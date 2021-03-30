//
//  ChatViewModel.swift
//  Speezy
//
//  Created by Matt Beaney on 14/01/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import UIKit
import FirebaseAuth

protocol ChatViewModelDelegate: AnyObject {
    var viewHeight: CGFloat { get }
}

class ChatViewModel: NewItemGenerating {
    weak var delegate: ChatViewModelDelegate?
    
    var updateReadDebouncer = Debouncer(seconds: 1.0)
    
    enum Change {
        case chattersLoaded(chatterNames: String)
        case leftChat
        case loading(Bool)
        case loaded
        case itemInserted(index: Int)
        case readStatusReloaded(index: [Int])
        case itemRemoved(index: Int)
        case finishedRecording
        case editingDiscarded(AudioItem)
    }
    
    typealias ChangeBlock = (Change) -> Void
    var didChange: ChangeBlock?
    private(set) var items = [MessageCellModel]()
    
    let messageFetcher = MessageFetcher()
    let updateQueue = DispatchQueue(label: "chatViewModelQueue")
    
    private lazy var messageCreator = MessageCreator()
    private lazy var messageDeleter = MessageDeleter()
    private lazy var chatDeleter = ChatDeleter()
    private lazy var chatterFetcher = ChattersFetcher()
    
    var colors: [String: UIColor] = [String: UIColor]()
    
    let store: Store
    let audioCloudManager = CloudAudioManager()
    let chatPushManager = ChatPushManager()
    
    private var activeAudioManager: AudioManager?
    
    private(set) var chat: Chat
    private var chatters: [Chatter] = []
    
    private var currentAudioFile: AudioItem?
    private var stagedText: String?
    
    var groupTitleText: String {
        chat.computedTitle(currentUserId: currentUserId)
    }

    var currentUserId: String? {
        Auth.auth().currentUser?.uid
    }
    
    var shouldShowEmptyView: Bool {
        items.isEmpty
    }
    
    init(chat: Chat, store: Store) {
        self.chat = chat
        self.store = store
    }
    
    func setAudioItem(_ item: AudioItem) {
        currentAudioFile = item.withoutStagingPath()
        LocalAudioManager.createOriginalFromStaged(item: item)
    }
    
    func leaveChat() {
        guard let userId = currentUserId else {
            return
        }
        
        chatDeleter.deleteChat(
            chat: chat,
            chatters: chatters,
            userId: userId
        ) { (result) in
            self.didChange?(.leftChat)
        }
    }
    
    func cancelAudioItem() {
        guard let item = currentAudioFile else {
            return
        }
        
        LocalAudioManager.deleteAudioFiles(item: item)
        currentAudioFile = nil
    }
    
    func setMessageText(_ text: String) {
        self.stagedText = text
    }
    
    func startPlaying(audioManager: AudioManager) {
        self.activeAudioManager?.stop()
        
        audioManager.play()
    }
    
    func stopObserving() {
        store.messagesStore.removeMessagesObserver(self)
        store.chatStore.removeChatListObserver(self)
    }
}

// MARK: Receiving
extension ChatViewModel {
    func listenForData() {
        chatterFetcher.fetchChatters(chat: chat) { (result) in
            switch result {
            case let .success(chatters):
                self.chatters = chatters
                
                let chatterNames = chatters.map {
                    if $0.id == self.currentUserId {
                        return "You"
                    } else {
                        return "\($0.displayName)"
                    }
                }.joined(separator: ", ")
                
                self.didChange?(.chattersLoaded(chatterNames: chatterNames))
                self.store.messagesStore.addMessagesObserver(
                    self,
                    chat: self.chat
                )
                
                chatters.forEach {
                    self.colors[$0.id] = SpeezyProfileViewGenerator.randomColor
                }
            case .failure:
                break
            }
        }
        
        store.chatStore.addChatListObserver(self)
    }
    
    func loadMoreMessages() {
        store.messagesStore.fetchNextPage(chat: chat, chatters: chatters, queryCount: 5)
    }
    
    private func messageIsFavourite(message: Message) -> Bool {
        store.favouritesStore.favourites.contains {
            message.audioId == $0.id
        }
    }
    
    private func fetchMessages() {
        DispatchQueue.main.async {
            let queryCount: UInt = {
                guard let viewHeight = self.delegate?.viewHeight else {
                    return 5
                }
                
                let count = viewHeight / 120.0
                return UInt(count) + 2
            }()
            
            self.didChange?(.loading(true))
            self.store.messagesStore.fetchNextPage(
                chat: self.chat,
                chatters: self.chatters,
                queryCount: queryCount
            )
        }
    }
    
    func toggleFavourite(on message: Message) {
        let favouriter = Favouriter()
        favouriter.toggleFavourite(
            currentFavourites: store.favouritesStore.favourites,
            message: message
        ) { _ in
            // no op.
        }
    }
}


// MARK: Sending
extension ChatViewModel {
    func sendStagedItem() {
        if let item = currentAudioFile, let data = item.fileUrl.data {
            sendAudioFile(item: item, data: data)
        } else {
            updateDatabaseRecords(item: nil)
        }
    }
    
    private func sendAudioFile(item: AudioItem, data: Data) {
        CloudAudioManager.uploadAudioClip(
            id: item.id,
            data: data
        ) { [weak self] (result) in
            guard let self = self else {
                return
            }
            
            switch result {
            case let .success(url):
                self.updateDatabaseRecords(item: item.withRemoteUrl(url))
            case let .failure(error):
                break
            }
        }
    }

    func deleteMessage(message: Message) {
        messageDeleter.deleteMessage(message: message, chat: chat)
        
        guard let audioId = message.audioId else {
            return
        }
        
        CloudAudioManager.deleteAudioClip(id: audioId)
    }
    
    func discardItem(_ item: AudioItem) {
        guard let stagedAudioFile = self.currentAudioFile else {
            return
        }
        
        let manager = AudioManager(item: item)
        manager.discard {
            self.didChange?(.editingDiscarded(stagedAudioFile))
        }
    }
    
    private func updateReadBy() {
        updateReadDebouncer.debounce { [weak self] in
            guard let self = self, let userId = self.currentUserId else {
                return
            }

            let updatedDate = Date().timeIntervalSince1970
            ChatUpdater().updateReadBy(
                chatId: self.chat.id,
                userId: userId,
                time: updatedDate
            )
        }
    }
    
    private func updateDatabaseRecords(item: AudioItem?) {
        guard
            let id = Auth.auth().currentUser?.uid,
            let chatter = chatters.chatter(for: id)
        else {
            // TODO: Handle error here.
            assertionFailure("User not found")
            return
        }
        
        let message = Message(
            id: UUID().uuidString,
            chatter: chatter,
            sent: Date(),
            message: self.stagedText,
            audioId: item?.id,
            audioUrl: item?.remoteUrl,
            attachmentUrl: nil,
            duration: item?.calculatedDuration,
            readBy: [chatter]
        )
                
        // First, insert the message.
        messageCreator.insertMessage(
            chats: [chat],
            message: message
        ) { [weak self] (result) in
            guard let self = self else {
                return
            }
            
            switch result {
            case let .success(message):
                self.chat = self.chat.withLastMessage(message.formattedMessage)
                        
                self.didChange?(.finishedRecording)
                
                self.chatPushManager.sendNotification(
                    message: message.formattedMessage,
                    chat: self.chat,
                    chatters: self.chatters,
                    from: chatter
                )
                
                self.stagedText = nil
                self.currentAudioFile = nil
            case let .failure(error):
                break
            }
        }
    }
}

extension ChatViewModel: MessagesObserver {
    func messageAdded(chatId: String, message: Message) {
        guard chatId == chat.id else {
            return
        }
        
        let cellModel = MessageCellModel(
            message: message,
            chat: self.chat,
            chatters: self.chatters,
            currentUserId: Auth.auth().currentUser?.uid ?? "",
            isFavourite: self.messageIsFavourite(message: message),
            color: colors[message.chatter.id]
        )
        
        self.updateQueue.async {
            let oldItems = self.items
            self.items = self.items.inserting(cellModel)
            
            if oldItems.count != self.items.count {
                self.didChange?(.itemInserted(index: 0))
            }
            
            if let currentUserId = self.currentUserId, message.chatter.id != currentUserId {
                self.updateReadBy()
            }
        }
    }
    
    func messageRemoved(chatId: String, message: Message) {
        guard chatId == chat.id else {
            return
        }
        
        self.updateQueue.async {
            guard let index = self.items.index(message.id) else {
                return
            }
            
            self.items = self.items.removing(message.id)
            self.didChange?(.itemRemoved(index: index))
        }
    }
    
    func pagedMessages(
        chatId: String,
        newMessages: [Message],
        allMessages: [Message]
    ) {
        guard chatId == chat.id else {
            return
        }
        
        processMessages(messages: allMessages)
    }
    
    func initialMessages(chatId: String, messages: [Message]) {
        guard chatId == chat.id else {
            return
        }
        
        if messages.isEmpty {
            fetchMessages()
        } else {
            processMessages(messages: messages)
        }
    }
    
    private func processMessages(messages: [Message]) {
        guard let userId = self.currentUserId else {
            return
        }
        
        self.items = messages.map {
            MessageCellModel(
                message: $0,
                chat: self.chat,
                chatters: self.chatters,
                currentUserId: userId,
                isFavourite: self.messageIsFavourite(message: $0),
                color: self.colors[$0.chatter.id]
            )
        }

        self.didChange?(.loaded)
        self.updateReadBy()
        self.didChange?(.loading(false))
    }
}

extension ChatViewModel: ChatListObserver {
    func chatUpdated(chat: Chat, in chats: [Chat]) {
        guard self.chat.id == chat.id, let userId = self.currentUserId else {
            return
        }
        
        updateQueue.async {
            self.reloadReadStatus(chat: chat, userId: userId)
        }
    }
    
    private func reloadReadStatus(chat: Chat, userId: String) {
        self.chat = chat
        
        guard let userId = self.currentUserId else {
            return
        }
        
        var updatedItems = [MessageCellModel]()
        
        
        self.items = self.items.map {
            if $0.message.chatter.id != userId {
                return $0
            }
            
            var newMessage = $0.message
            newMessage.readBy = chatters.readChatters(
                forMessageDate: newMessage.sent,
                chat: chat
            )
            
            let cellModel = MessageCellModel(
                message: newMessage,
                chat: self.chat,
                chatters: self.chatters,
                currentUserId: userId,
                isFavourite: self.messageIsFavourite(
                    message: $0.message
                ),
                color: self.colors[newMessage.chatter.id]
            )
            
            if newMessage != $0.message {
                updatedItems.append(cellModel)
            }
            
            return cellModel
        }
        
        let indexes: [Int] = updatedItems.filter {
            $0.message.chatter.id == userId
        }.compactMap {
            self.items.index($0)
        }
        
        self.didChange?(.readStatusReloaded(index: indexes))
    }
    
    func chatsPaged(chats: [Chat]) {}
    func chatAdded(chat: Chat, in chats: [Chat]) {}
    func initialChatsReceived(chats: [Chat]) {}
    func chatRemoved(chat: Chat, chats: [Chat]) {}
}
