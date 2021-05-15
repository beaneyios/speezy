//
//  ChatOptionsViewModel.swift
//  Speezy
//
//  Created by Matt Beaney on 12/05/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation
import FirebaseAuth

class ChatOptionsViewModel {
    enum Change {
        case updated
        case chatDeleted
    }
    
    var didChange: ((Change) -> Void)?
    var chat: Chat
    let chatUpdater = ChatUpdater()
    
    var chatters: [Chatter] {
        chat.chatters
    }
    
    var currentChatter: Chatter? {
        chat.chatters.first {
            $0.id == Auth.auth().currentUser?.uid
        }
    }
    
    var canRemoveUsers: Bool {
        guard
            let currentUserId = Auth.auth().currentUser?.uid,
            let ownerId = chat.ownerId
        else {
            return false
        }
        
        return currentUserId == ownerId
    }
    
    init(chat: Chat, store: Store = Store.shared) {
        self.chat = chat
        store.chatStore.addChatListObserver(self)
    }
    
    func userIsAdmin(chatter: Chatter) -> Bool {
        guard let chatOwnerId = chat.ownerId else {
            return false
        }
        
        return chatOwnerId == chatter.id
    }
    
    func removeUser(chatter: Chatter) {
        chatUpdater.removeUserFromChat(
            chatter: chatter,
            chat: chat
        )
    }
}

extension ChatOptionsViewModel: ChatListObserver {
    func chatUpdated(chat: Chat, in chats: [Chat]) {
        guard chat.id == self.chat.id else {
            return
        }
        
        self.chat = chat
        didChange?(.updated)
    }
    
    func chatRemoved(chat: Chat, chats: [Chat]) {
        guard chat.id == self.chat.id else {
            return
        }
        
        didChange?(.chatDeleted)
    }
    
    func chatsPaged(chats: [Chat]) {}
    func chatAdded(chat: Chat, in chats: [Chat]) {}
    func initialChatsReceived(chats: [Chat]) {}
}
