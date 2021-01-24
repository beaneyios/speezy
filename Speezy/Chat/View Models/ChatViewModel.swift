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
    }
    
    typealias ChangeBlock = (Change) -> Void
    var didChange: ChangeBlock?
    private(set) var items = [MessageCellModel]()
    
    let chatManager = DatabaseChatManager()
    let audioClipManager = DatabaseAudioManager()
    let audioCloudManager = CloudAudioManager()
    
    private var activeAudioManager: AudioManager?
    
    private var chat: Chat
    private var stagedAudioFile: AudioItem?
    private var stagedText: String?
    
    private var noMoreMessages = false
    
    var groupTitleText: String {
        chat.title
    }

    var currentUserId: String {
        Auth.auth().currentUser?.uid ?? ""
    }
    
    var shouldShowEmptyView: Bool {
        items.isEmpty
    }
    
    init(chat: Chat) {
        self.chat = chat
    }
    
    func listenForData() {
        didChange?(.loading(true))
        chatManager.fetchChatters(chat: chat) { (result) in
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
        chatManager.fetchMessages(chat: chat) { (result) in
            switch result {
            case let .success(messages):
                self.items = messages.map {
                    MessageCellModel(
                        message: $0,
                        chat: self.chat,
                        currentUserId: self.currentUserId
                    )
                }

                self.didChange?(.loaded)
                self.listenForNewMessages(mostRecentMessage: messages.first)
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
        chatManager.fetchMessages(chat: chat, mostRecentMessage: mostRecentMessage) { (result) in
            switch result {
            case let .success(newMessages):
                let newMessageModels = newMessages.map {
                    MessageCellModel(
                        message: $0,
                        chat: self.chat,
                        currentUserId: self.currentUserId
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
        chatManager.listenForNewMessages(mostRecentMessage: mostRecentMessage, chat: chat) { (result) in
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
    
    func setAudioItem(_ item: AudioItem) {
        stagedAudioFile = item
    }
    
    func cancelAudioItem() {
        guard let item = stagedAudioFile else {
            return
        }
        
        FileManager.default.deleteExistingURL(item.fileUrl)
        stagedAudioFile = nil
    }
    
    func setMessageText(_ text: String) {
        self.stagedText = text
    }
    
    func startPlaying(audioManager: AudioManager) {
        self.activeAudioManager?.stop()
        
        audioManager.play()
    }
}

extension ChatViewModel {
    func sendStagedItem() {
        guard let item = stagedAudioFile, let data = try? Data(contentsOf: item.fileUrl) else {
            return
        }
        
        CloudAudioManager.uploadAudioClip(
            data,
            path: "audio_clips/\(item.id).m4a"
        ) { (result) in
            switch result {
            case let .success(url):
                self.updateDatabaseRecords(item: item.withRemoteUrl(url))
            case let .failure(error):
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
        
        chatManager.insertMessage(
            item: item,
            message: message,
            chat: chat
        ) { (result) in
            switch result {
            case let .success(message):
                self.updateAudioDatabaseRecords(item: item, message: message)
            case let .failure(error):
                break
            }
        }
    }
    
    private func updateAudioDatabaseRecords(item: AudioItem, message: Message) {
        DatabaseAudioManager.updateDatabaseReference(item) { (result) in
            switch result {
            case .success:
                // TODO: Not sure how to handle success, we're listening for new chat items automatically.
                break
            case let .failure(error):
                break
            }
        }
    }
}
