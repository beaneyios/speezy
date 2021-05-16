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
    
    enum Item {
        case chatter(Chatter)
        case leaveButton
    }
    
    var didChange: ((Change) -> Void)?
    var chat: Chat
    let chatUpdater = ChatUpdater()
    
    var items: [Item] {
        let chatterItems = chatters.map {
            return Item.chatter($0)
        }
        
        return chatterItems + [.leaveButton]
    }
    
    var chatters: [Chatter] {
        chat.chatters
    }
    
    var currentChatter: Chatter? {
        chat.chatters.first {
            $0.id == Auth.auth().currentUser?.uid
        }
    }
    
    init(chat: Chat, store: Store = Store.shared) {
        self.chat = chat
        store.chatStore.addChatListObserver(self)
    }
    
    func removeUser(at indexPath: IndexPath) {
        guard let chatter = self.chatter(at: indexPath) else {
            return
        }
        
        chatUpdater.removeUserFromChat(
            chatter: chatter,
            chat: chat
        )
    }
    
    func leaveChat() {
        guard let currentChatter = currentChatter else {
            return
        }
        
        chatUpdater.removeUserFromChat(
            chatter: currentChatter,
            chat: chat
        )
    }
}

extension ChatOptionsViewModel {
    func canRemoveUsers(indexPath: IndexPath) -> Bool {
        guard
            let currentUserId = Auth.auth().currentUser?.uid,
            let ownerId = chat.ownerId,
            let chatter = self.chatter(at: indexPath)
        else {
            return false
        }
        
        return currentUserId == ownerId && chatter.id != currentUserId
    }
    
    func userIsAdmin(chatter: Chatter) -> Bool {
        guard let chatOwnerId = chat.ownerId else {
            return false
        }
        
        return chatOwnerId == chatter.id
    }
    
    private func chatter(at indexPath: IndexPath) -> Chatter? {
        let chatterItem = items[indexPath.row]
        
        guard case let .chatter(chatter) = chatterItem else {
            return nil
        }
        
        return chatter
    }
}

extension ChatOptionsViewModel: ChatListObserver {
    func chatUpdated(chat: Chat, in chats: [Chat]) {
        guard chat.id == self.chat.id else {
            return
        }
        
        self.chat = chat
        
        if currentChatter == nil {
            didChange?(.chatDeleted)
        } else {
            didChange?(.updated)
        }
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
