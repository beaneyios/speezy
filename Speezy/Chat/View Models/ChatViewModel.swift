//
//  ChatViewModel.swift
//  Speezy
//
//  Created by Matt Beaney on 14/01/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import UIKit
import FirebaseAuth

class ChatViewModel: NewItemGenerating {
    enum Change {
        case leftChat
        case loading(Bool)
        case loaded
        case itemInserted(index: Int)
        case finishedRecording
        case editingDiscarded(AudioItem)
        case itemReloaded(index: Int)
        case itemRemoved(index: Int)
    }
    
    typealias ChangeBlock = (Change) -> Void
    var didChange: ChangeBlock?
    private(set) var items = [MessageCellModel]()
    
    let groupFetcher = GroupFetcher()
    let messageFetcher = MessageFetcher()
    
    private lazy var messageCreator = MessageCreator()
    private lazy var messageListener = {
        MessageListener(chat: chat)
    }()
    private lazy var messageDeleter = MessageDeleter()
    private lazy var chatDeleter = ChatDeleter()
    
    let store: Store
    let audioCloudManager = CloudAudioManager()
    let chatPushManager = ChatPushManager()
    
    private var activeAudioManager: AudioManager?
    
    private(set) var chat: Chat
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
        
        chatDeleter.deleteChat(chat: chat, userId: userId) { (result) in
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
        didChange?(.loading(true))
        groupFetcher.fetchChatters(chat: chat) { [weak self] (result) in
            guard let self = self else {
                return
            }
            
            switch result {
            case let .success(chatters):
                self.chat = self.chat.withChatters(chatters: chatters)
                self.fetchMessages()
            case let .failure(error):
                break
            }
        }
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
        messageFetcher.fetchMessages(chat: chat) { [weak self] (result) in
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
                    self.didChange?(.itemReloaded(index: index))
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
        messageFetcher.fetchMessages(chat: chat, mostRecentMessage: mostRecentMessage) { [weak self] (result) in
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
                        currentUserId: userId,
                        isFavourite: self.messageIsFavourite(message: $0)
                    )
                }
                
                if newMessageModels.isEmpty {
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
                    currentUserId: Auth.auth().currentUser?.uid ?? "",
                    isFavourite: self.messageIsFavourite(message: message)
                )
                                
                let oldItems = self.items
                self.items = self.items.inserting(cellModel)
                                
                if oldItems.count != self.items.count {
                    self.didChange?(.itemInserted(index: 0))
                } else {
                    self.didChange?(.itemReloaded(index: 0))
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
                    self.items = self.items.removing(messageId)
                    self.didChange?(.itemRemoved(index: index))
                    
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
        
        self.chat = chat.withReadBy(userId: userId, time: Date().timeIntervalSince1970)
        ChatUpdater().updateChat(chatValue: .readBy(chat.readBy.toString), chatId: chat.id)
    }
    
    private func updateDatabaseRecords(item: AudioItem) {
        guard
            let id = Auth.auth().currentUser?.uid,
            let chatter = chat.chatters.chatter(for: id)
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
            readBy: []
        )
        
        let updatedTime = Date().timeIntervalSince1970
        let readByCurrent = ReadBy(id: id, time: updatedTime)
        
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
                    .withLastUpdated(updatedTime)
                    .withReadBy(readBy: [readByCurrent])
                        
                self.didChange?(.finishedRecording)
                
                self.chatPushManager.sendNotification(
                    message: message.formattedMessage,
                    chat: self.chat,
                    from: chatter
                )
            case let .failure(error):
                break
            }
        }
    }
}
