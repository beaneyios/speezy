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
        case loadedChats
        case loadedProfile
        case loading(Bool)
    }
    
    private(set) var selectedChats = [Chat]()
    
    private(set) var items = [ChatSelectionCellModel]()
    private var chats = [Chat]()
    var didChange: ((Change) -> Void)?
    
    private let store: Store
    private let audioItem: AudioItem?
    private let message: Message?
    
    private let messageCreator = MessageCreator()
    private let chatUpdater = ChatUpdater()
    private let chatPushManager = ChatPushManager()
    
    private var profile: Profile?
    
    var shouldShowEmptyView: Bool {
        items.isEmpty
    }
    
    var userId: String? {
        Auth.auth().currentUser?.uid
    }
    
    init(
        store: Store,
        audioItem: AudioItem?,
        message: Message?
    ) {
        self.store = store
        self.audioItem = audioItem
        self.message = message
    }
    
    func loadData() {
        store.profileStore.addProfileObserver(self)
        store.chatStore.addChatListObserver(self)
    }
    
    func selectChat(chat: Chat) {
        if let chatIndex = selectedChats.index(chat) {
            selectedChats.remove(at: chatIndex)
        } else {
            selectedChats.append(chat)
        }
    }
    
    func sendToSelectedChats() {
        didChange?(.loading(true))
        
        guard
            let userId = userId,
            let profile = self.profile
        else {
            return
        }
        
        if let audioItem = audioItem {
            insertMessage(
                userId: userId,
                item: audioItem,
                profile: profile
            )
        } else if let message = message {
            insertMessage(
                message: message,
                userId: userId,
                profile: profile
            )
        }
    }
    
    private func insertMessage(
        userId: String,
        item: AudioItem,
        profile: Profile
    ) {
        let chatter = Chatter(
            id: userId,
            displayName: profile.name,
            profileImageUrl: profile.profileImageUrl,
            color: UIColor.random
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
            readBy: [],
            playedBy: [],
            forwarded: true,
            replyTo: nil
        )
        
        insertMessage(message: message, chatter: chatter)
    }
    
    private func insertMessage(
        message: Message,
        userId: String,
        profile: Profile
    ) {
        let chatter = Chatter(
            id: userId,
            displayName: profile.name,
            profileImageUrl: profile.profileImageUrl,
            color: UIColor.random
        )
        
        var newMessage = message
        newMessage.chatter = chatter
        newMessage.sent = Date()
        newMessage.id = UUID().uuidString
        newMessage.forwarded = true
        insertMessage(message: newMessage, chatter: chatter)
    }
    
    private func insertMessage(message: Message, chatter: Chatter) {
        messageCreator.insertMessage(
            chats: selectedChats,
            message: message
        ) { (result) in
            switch result {
            case let .success(message):
                self.didChange?(.messageInserted)
                self.chatPushManager.sendNotification(
                    message: message.formattedMessage,
                    chats: self.selectedChats,
                    from: chatter
                )
            case let .failure(error):
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

        self.didChange?(.loadedChats)
        self.didChange?(.loading(false))
    }
}

extension ChatShareViewModel: ChatListObserver {
    func initialChatsReceived(chats: [Chat]) {
        updateCellModels(chats: chats)
    }
    
    func chatsPaged(chats: [Chat]) {}
    func chatAdded(chat: Chat, in chats: [Chat]) {}
    func chatUpdated(chat: Chat, in chats: [Chat]) {}
    func chatRemoved(chat: Chat, chats: [Chat]) {}
}

extension ChatShareViewModel: ProfileObserver {
    func initialProfileReceived(profile: Profile) {
        self.profile = profile
        didChange?(.loading(false))
        self.didChange?(.loadedProfile)
    }
    
    func profileUpdated(profile: Profile) {
        self.profile = profile
    }
}
