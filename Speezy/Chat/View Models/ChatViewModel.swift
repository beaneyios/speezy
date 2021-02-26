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
    
    enum Change {
        case leftChat
        case loading(Bool)
        case loaded
        case itemInserted(index: Int)
        case finishedRecording
        case editingDiscarded(AudioItem)
        case itemsReloaded(index: [Int])
        case itemRemoved(index: Int)
    }
    
    typealias ChangeBlock = (Change) -> Void
    var didChange: ChangeBlock?
    private(set) var items = [MessageCellModel]()
    
    let messageFetcher = MessageFetcher()
    let updateQueue = DispatchQueue(label: "chatViewModelQueue")
    
    private lazy var messageCreator = MessageCreator()
    private lazy var messageListener = MessageListener(chat: chat, chatters: chatters)
    private lazy var messageDeleter = MessageDeleter()
    private lazy var chatDeleter = ChatDeleter()
    private lazy var chatterFetcher = ChattersFetcher()
    
    let store: Store
    let audioCloudManager = CloudAudioManager()
    let chatPushManager = ChatPushManager()
    
    private var activeAudioManager: AudioManager?
    
    private(set) var chat: Chat
    private var chatters: [Chatter] = []
    
    private var currentAudioFile: AudioItem?
    private var stagedText: String?
    
    private var noMoreMessages = false
    
    var groupTitleText: String {
        chat.title
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
}

// MARK: Receiving
extension ChatViewModel {
    func listenForData() {
        chatterFetcher.fetchChatters(chat: chat) { (result) in
            switch result {
            case let .success(chatters):
                self.chatters = chatters
                self.fetchMessages()
            case let .failure(error):
                break
            }
        }
        
        store.chatStore.addChatListObserver(self)
    }
    
    func stopListeningForData() {
        messageListener.stopListening()
    }
    
    private func messageIsFavourite(message: Message) -> Bool {
        store.favouritesStore.favourites.contains {
            message.audioId == $0.id
        }
    }
    
    private func fetchMessages() {
        let queryCount: UInt = {
            guard let viewHeight = self.delegate?.viewHeight else {
                return 5
            }
            
            let count = viewHeight / 120.0
            return UInt(count) + 2
        }()
        
        didChange?(.loading(true))
        messageFetcher.fetchMessages(
            chat: chat,
            chatters: chatters,
            queryCount: queryCount
        ) { [weak self] (result) in
            guard let self = self else {
                return
            }
            
            switch result {
            case let .success(messages):
                guard let userId = self.currentUserId else {
                    return
                }
                
                self.items = messages.map {
                    MessageCellModel(
                        message: $0,
                        chat: self.chat,
                        chatters: self.chatters,
                        currentUserId: userId,
                        isFavourite: self.messageIsFavourite(message: $0)
                    )
                }

                self.didChange?(.loaded)
                self.listenForNewMessages(mostRecentMessage: messages.first)
                self.listenForDeletedMessages()
                self.updateReadBy()
            case let .failure(error):
                break
            }
            
            self.didChange?(.loading(false))
        }
    }
    
    func toggleFavourite(on message: Message) {
        let favouriter = Favouriter()
        favouriter.toggleFavourite(
            currentFavourites: store.favouritesStore.favourites,
            message: message
        ) { [weak self] (result) in
            guard let self = self else {
                return
            }
            
            switch result {
            case let .success(favourited):
                guard var modelToUpdate = self.items.first(withId: message.id) else {
                    return
                }
                
                modelToUpdate.isFavourite = favourited
                self.items = self.items.replacing(modelToUpdate)
                
                if let index = self.items.index(modelToUpdate) {
                    self.didChange?(.itemsReloaded(index: [index]))
                }
            case .failure:
                break
            }
        }
    }
    
    func loadMoreMessages() {
        guard
            let mostRecentMessage = items.last?.message,
            !noMoreMessages
        else {
            return
        }
        
        didChange?(.loading(true))
        messageFetcher.fetchMessages(
            chat: chat,
            chatters: chatters,
            queryCount: 5,
            mostRecentMessage: mostRecentMessage
        ) { [weak self] (result) in
            guard let self = self else {
                return
            }
            
            switch result {
            case let .success(newMessages):
                guard let userId = self.currentUserId else {
                    return
                }
                
                let newMessageModels = newMessages.map {
                    MessageCellModel(
                        message: $0,
                        chat: self.chat,
                        chatters: self.chatters,
                        currentUserId: userId,
                        isFavourite: self.messageIsFavourite(message: $0)
                    )
                }
                
                if newMessages.count == 1 && self.items.contains(message: newMessages[0]) {
                    self.noMoreMessages = true
                } else {
                    self.items.append(contentsOf: newMessageModels)
                    self.didChange?(.loaded)
                }
            case let .failure(error):
                assertionFailure("Errored with error \(error)")
                // TODO: Handle errors.
            }
            
            self.didChange?(.loading(false))
        }
    }
        
    private func listenForNewMessages(mostRecentMessage: Message?) {
        messageListener.listenForNewMessages(mostRecentMessage: mostRecentMessage) { [weak self] (result) in
            guard let self = self else {
                return
            }
            
            switch result {
            case let .success(message):
                let cellModel = MessageCellModel(
                    message: message,
                    chat: self.chat,
                    chatters: self.chatters,
                    currentUserId: Auth.auth().currentUser?.uid ?? "",
                    isFavourite: self.messageIsFavourite(message: message)
                )
                
                self.updateQueue.async {
                    let oldItems = self.items
                    self.items = self.items.inserting(cellModel)
                                    
                    if oldItems.count != self.items.count {
                        self.didChange?(.itemInserted(index: 0))
                    } else {
                        self.didChange?(.itemsReloaded(index: [0]))
                    }
                    
                    if let currentUserId = self.currentUserId, message.chatter.id != currentUserId {
                        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.0) {
                            self.updateReadBy()
                        }
                    }
                }
            case let .failure(error):
                break
            }
        }
    }
    
    private func listenForDeletedMessages() {
        messageListener.listenForDeletedMessages { [weak self] (result) in
            guard let self = self else {
                return
            }
            
            switch result {
            case let .success(messageId):
                if let index = self.items.index(messageId) {
                    self.updateQueue.async {
                        self.items = self.items.removing(messageId)
                        self.didChange?(.itemRemoved(index: index))
                    }
                                        
                    // We need to renew this, since the "most recent message" will be different.
                    if index == 0 {
                        self.listenForNewMessages(mostRecentMessage: self.items.first?.message)
                    }
                }
            case let.failure(error):
                break
            }
        }
    }
}


// MARK: Sending
extension ChatViewModel {
    func sendStagedItem() {
        guard let item = currentAudioFile, let data = item.fileUrl.data else {
            return
        }
        
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
        guard let userId = currentUserId else {
            return
        }

        let updatedDate = Date().timeIntervalSince1970
        ChatUpdater().updateReadBy(chatId: chat.id, userId: userId, time: updatedDate)
    }
    
    private func updateDatabaseRecords(item: AudioItem) {
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
            audioId: item.id,
            audioUrl: item.remoteUrl,
            attachmentUrl: nil,
            duration: item.calculatedDuration,
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
            case let .failure(error):
                break
            }
        }
    }
}

extension ChatViewModel: ChatListObserver {
    func chatUpdated(chat: Chat, in chats: [Chat]) {
        guard self.chat.id == chat.id, let userId = self.currentUserId else {
            return
        }
        
        updateQueue.async {
            self.reloadChatItems(chat: chat, userId: userId)
        }
    }
    
    private func reloadChatItems(chat: Chat, userId: String) {
        self.chat = chat
        
        var updatedItems = [MessageCellModel]()
        
        self.items = self.items.map {
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
                isFavourite: self.messageIsFavourite(message: $0.message)
            )
            
            if newMessage != $0.message {
                updatedItems.append(cellModel)
            }
            
            return cellModel
        }
        
        let indexes: [Int] = updatedItems.compactMap {
            self.items.index($0)
        }
        
        self.didChange?(.itemsReloaded(index: indexes))
    }
    
    func chatAdded(chat: Chat, in chats: [Chat]) {}
    func initialChatsReceived(chats: [Chat]) {}
    func chatRemoved(chat: Chat, chats: [Chat]) {}
}
