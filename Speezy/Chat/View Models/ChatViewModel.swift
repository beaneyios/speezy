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
        case loading(Bool)
        case loaded
        case itemInserted(index: Int)
        case finishedRecording
        case editingDiscarded(AudioItem)
    }
    
    typealias ChangeBlock = (Change) -> Void
    var didChange: ChangeBlock?
    private(set) var items = [MessageCellModel]()
    
    let groupFetcher = GroupFetcher()
    let messageFetcher = MessageFetcher()
    
    private lazy var messageCreator = MessageCreator(chat: chat)
    private lazy var messageListener = MessageListener(chat: chat)
    
    let audioClipManager = DatabaseAudioManager()
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
    
    init(chat: Chat) {
        self.chat = chat
    }
    
    func setAudioItem(_ item: AudioItem) {
        currentAudioFile = item.withoutStagingPath()
        LocalAudioManager.createOriginalFromStaged(item: item)
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
        groupFetcher.fetchChatters(chat: chat) { (result) in
            switch result {
            case let .success(chatters):
                self.chat = self.chat.withChatters(chatters: chatters)
                self.fetchMessages()
            case let .failure(error):
                break
            }
        }
    }
    
    private func fetchMessages() {
        messageFetcher.fetchMessages(chat: chat) { (result) in
            switch result {
            case let .success(messages):
                guard let userId = self.currentUserId else {
                    return
                }
                
                self.items = messages.map {
                    MessageCellModel(
                        message: $0,
                        chat: self.chat,
                        currentUserId: userId
                    )
                }

                self.didChange?(.loaded)
                self.listenForNewMessages(mostRecentMessage: messages.first)
                self.updateReadBy()
            case let .failure(error):
                break
            }
            
            self.didChange?(.loading(false))
        }
    }
    
    func loadMoreMessages(index: Int) {
        guard
            index == items.count - 1,
            let mostRecentMessage = items.last?.message,
            !noMoreMessages
        else {
            return
        }
        
        didChange?(.loading(true))
        messageFetcher.fetchMessages(chat: chat, mostRecentMessage: mostRecentMessage) { (result) in
            switch result {
            case let .success(newMessages):
                guard let userId = self.currentUserId else {
                    return
                }
                
                let newMessageModels = newMessages.map {
                    MessageCellModel(
                        message: $0,
                        chat: self.chat,
                        currentUserId: userId
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
        messageListener.listenForNewMessages(mostRecentMessage: mostRecentMessage) { (result) in
            switch result {
            case let .success(message):
                let cellModel = MessageCellModel(
                    message: message,
                    chat: self.chat,
                    currentUserId: Auth.auth().currentUser?.uid ?? ""
                )
                self.items.insert(cellModel, at: 0)
                self.didChange?(.itemInserted(index: 0))
            case let .failure(error):
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
        ) { (result) in
            switch result {
            case let .success(url):
                self.updateDatabaseRecords(item: item.withRemoteUrl(url))
            case let .failure(error):
                break
            }
        }
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
        
        // Only update the read by if this is the first time you are reading it.
        if chat.readBy.contains(userId) {
            return
        }
        
        let newChat = chat.withReadBy(userId: userId)
        
        ChatUpdater().updateChat(chat: newChat) { (result) in
            switch result {
            case let .success(newChat):
                self.chat = newChat
            case let .failure(error):
                // TODO: Handle error.
                break
            }
        }
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
        
        // First, insert the message.
        messageCreator.insertMessage(item: item, message: message) { (result) in
            switch result {
            case let .success(message):
                let mostRecentMessage = message.message ?? "New message from \(message.chatter.displayName)"
                let newChat = self.chat.withLastMessage(mostRecentMessage)
                    .withLastUpdated(Date().timeIntervalSince1970)
                    .withReadBy(readBy: [id])
                
                // Second, update chat metadata
                ChatUpdater().updateChat(chat: newChat) { (result) in
                    switch result {
                    case let .success(newChat):
                        self.chat = newChat
                        
                        // Third, update the audio reference
                        self.updateAudioDatabaseRecords(item: item, message: message)
                        
                        // Fourth, send a push notification to relevant users.
                        self.chatPushManager.sendNotification(
                            message: mostRecentMessage,
                            chat: newChat
                        )
                    case let .failure(error):
                        // TODO: Handle error.
                        break
                    }
                }
            case let .failure(error):
                break
            }
        }
    }
    
    private func updateAudioDatabaseRecords(item: AudioItem, message: Message) {
        DatabaseAudioManager.updateDatabaseReference(item) { (result) in
            switch result {
            case .success:
                self.didChange?(.finishedRecording)
            case let .failure(error):
                break
            }
        }
    }
}
