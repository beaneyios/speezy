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
        case loaded
        case itemInserted(index: Int)
    }
    
    typealias ChangeBlock = (Change) -> Void
    var didChange: ChangeBlock?
    private(set) var items = [MessageCellModel]()
    
    let chatManager = DatabaseChatManager()
    let audioClipManager = DatabaseAudioManager()
    let audioCloudManager = CloudAudioManager()
    
    private var chat: Chat
    private var stagedAudioFile: AudioItem?
    private var stagedText: String?
    
    init(chat: Chat) {
        self.chat = chat
    }
    
    func listenForData() {
        let currentUserId = Auth.auth().currentUser?.uid ?? ""
        
        chatManager.fetchMessages(chat: chat) { (result) in
            switch result {
            case let .success(messages):
                self.items = messages.map {
                    MessageCellModel(
                        message: $0,
                        chat: self.chat,
                        currentUserId: currentUserId
                    )
                }
                
                self.didChange?(.loaded)
            case let .failure(error):
                break
            }
        }
    }    
    
    func setAudioItem(_ item: AudioItem) {
        self.stagedAudioFile = item
    }
    
    func setMessageText(_ text: String) {
        self.stagedText = text
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
            audioUrl: item.remoteUrl,
            attachmentUrl: nil,
            duration: nil,
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
