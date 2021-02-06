//
//  ChatShareViewModel.swift
//  Speezy
//
//  Created by Matt Beaney on 05/02/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation
import FirebaseAuth

class ChatShareViewModel {
    enum Change: Equatable {
        case messageInserted
        case loaded
        case loading(Bool)
    }
    
    private(set) var selectedChats = [Chat]()
    
    private(set) var items = [ChatSelectionCellModel]()
    private var chats = [Chat]()
    var didChange: ((Change) -> Void)?
    
    private let store: Store
    private let audioItem: AudioItem
    
    private let messageCreator = MessageCreator()
    private let chatUpdater = ChatUpdater()
    private let chatPushManager = ChatPushManager()
    
    var shouldShowEmptyView: Bool {
        items.isEmpty
    }
    
    var userId: String? {
        Auth.auth().currentUser?.uid
    }
    
    init(store: Store, audioItem: AudioItem) {
        self.store = store
        self.audioItem = audioItem
    }
    
    func fetchChats() {
        guard let userId = Auth.auth().currentUser?.uid else {
            return
        }
        
        store.chatStore.addChatListObserver(self)
    }
    
    func selectChat(chat: Chat) {
        if let chatIndex = selectedChats.firstIndex(of: chat) {
            selectedChats.remove(at: chatIndex)
        } else {
            selectedChats.append(chat)
        }
    }
    
    func sendToSelectedChats() {
        didChange?(.loading(true))
        
        guard let userId = userId else {
            return
        }
        
        DatabaseProfileManager().fetchProfile(userId: userId) { (result) in
            switch result {
            case let .success(profile):
                self.insertMessage(
                    userId: userId,
                    item: self.audioItem,
                    profile: profile
                )
            case let .failure(error):
                break
            }
        }
    }
    
    private func insertMessage(userId: String, item: AudioItem, profile: Profile) {
        let chatter = Chatter(
            id: userId,
            displayName: profile.name,
            profileImageUrl: profile.profileImageUrl,
            pushToken: profile.pushToken
        )
        
        let message = Message(
            id: UUID().uuidString,
            chatter: chatter,
            sent: Date(),
            message: item.title,
            audioId: item.id,
            audioUrl: item.remoteUrl,
            attachmentUrl: nil,
            duration: item.calculatedDuration,
            readBy: []
        )
        
        messageCreator.insertMessage(
            chats: selectedChats,
            item: item,
            message: message
        ) { (result) in
            switch result {
            case let .success(message):
                self.updateChats(chatter: chatter, message: message)
            case let .failure(error):
                break
            }
        }
    }
    
    private func updateChats(chatter: Chatter, message: Message) {
        let updatedChats = self.selectedChats.map {
            $0.withLastUpdated(Date().timeIntervalSince1970)
                .withLastMessage(message.formattedMessage)
                .withReadBy(readBy: [chatter.id])
        }
        
        self.chatUpdater.updateChats(chats: updatedChats) { (result) in
            switch result {
            case let .success(chats):
                let mostRecentMessage = message.formattedMessage
                self.didChange?(.messageInserted)
                self.chatPushManager.sendNotification(
                    message: mostRecentMessage,
                    chats: chats,
                    from: chatter
                )
            case .failure:
                break
            }
            
        }
    }
    
    private func updateCellModels(chats: [Chat]) {
        self.chats = chats
        self.items = chats.map {
            ChatSelectionCellModel(
                chat: $0,
                currentUserId: self.userId,
                selected: self.selectedChats.contains($0)
            )
        }

        self.didChange?(.loaded)
        self.didChange?(.loading(false))
    }
}

extension ChatShareViewModel: ChatListObserver {
    func initialChatsReceived(chats: [Chat]) {
        updateCellModels(chats: chats)
    }
    
    func chatAdded(chat: Chat, in chats: [Chat]) {}
    func chatUpdated(chat: Chat, in chats: [Chat]) {}
    func chatRemoved(chat: Chat, chats: [Chat]) {}
}
