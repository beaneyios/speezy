//
//  ChatsListener.swift
//  Speezy
//
//  Created by Matt Beaney on 28/01/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation
import FirebaseDatabase

class ChatsListener {
    enum Change {
        case chatAdded(Chat)
        case chatUpdated(ChatValueChange)
        case chatRemoved(String)
    }
        
    var userChatQuery: DatabaseQuery?
    var didChange: ((Change) -> Void)?
    
    func listenForChatAdditions(userId: String) {
        let ref = Database.database().reference()
        let chatsChild = ref.child("users/\(userId)/chats")
        let query = chatsChild.queryOrderedByKey()
        query.observe(.childAdded) { (snapshot) in
            // First thing - fetch the chat so our store is set up.
            self.fetchChat(chatId: snapshot.key)
            
            // Second thing - listen for any future changes to the chat.
            self.listenForChatChanges(chatId: snapshot.key)
        }
    }
    
    func listenForChatDeletions(userId: String) {
        let ref = Database.database().reference()
        let chatsChild = ref.child("users/\(userId)/chats")
        let query = chatsChild.queryOrderedByKey()
        query.observe(.childRemoved) { (snapshot) in
            self.didChange?(.chatRemoved(snapshot.key))
        }
    }
    
    private func fetchChat(chatId: String) {
        let ref = Database.database().reference()
        let chatChild = ref.child("chats/\(chatId)")
        chatChild.observeSingleEvent(of: .value) { (snapshot) in
            guard
                let dict = snapshot.value as? NSDictionary,
                let chat = ChatParser.parseChat(key: snapshot.key, dict: dict)
            else {
                return
            }
            
            self.didChange?(.chatAdded(chat))
        }
    }
    
    private func listenForChatChanges(chatId: String) {
        let ref = Database.database().reference()
        let chatsChild: DatabaseReference = ref.child("chats/\(chatId)")
        let query = chatsChild.queryOrderedByKey()
        query.observe(.childChanged) { (snapshot) in
            guard
                let value = snapshot.value,
                let chatValue = ChatValue(key: snapshot.key, value: value)
            else {
                return
            }
            
            
            let change = ChatValueChange(chatId: chatId, chatValue: chatValue)
            self.didChange?(.chatUpdated(change))
        }
    }
}
