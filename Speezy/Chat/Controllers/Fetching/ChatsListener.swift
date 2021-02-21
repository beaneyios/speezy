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
    
    var queries: [String: DatabaseQuery] = [:]
    
    func listenForChatAdditions(userId: String) {
        let userIdQueryKey = "\(userId)_additions"
        removeQueryListener(forId: userIdQueryKey)
        
        let ref = Database.database().reference()
        let chatsChild = ref.child("users/\(userId)/chats")
        let query = chatsChild.queryOrderedByKey()
        
        query.observe(.childAdded) { (snapshot) in
            // First thing - fetch the chat so our store is set up.
            self.fetchChat(chatId: snapshot.key)
        } withCancel: { (error) in
            print(error)
        }

        queries[userIdQueryKey] = query
    }
    
    func listenForChatDeletions(userId: String) {
        let userIdQueryKey = "\(userId)_deletions"
        removeQueryListener(forId: userIdQueryKey)
        
        let ref = Database.database().reference()
        let chatsChild = ref.child("users/\(userId)/chats")
        let query = chatsChild.queryOrderedByKey()
        query.observe(.childRemoved) { (snapshot) in
            self.didChange?(.chatRemoved(snapshot.key))
            self.stopListeningForChatChanges(chatId: snapshot.key)
        }
        
        queries[userIdQueryKey] = query
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
            
            self.listenForChatChanges(chat: chat)
            self.didChange?(.chatAdded(chat))
        }
    }
    
    func stopListening() {
        queries.values.forEach {
            $0.removeAllObservers()
        }
        
        queries = [:]
    }
    
    private func stopListeningForChatChanges(chatId: String) {
        queries.keys.filter {
            $0.contains(chatId)
        }.compactMap {
            self.queries[$0]
        }.forEach {
            $0.removeAllObservers()
        }
    }
    
    private func removeQueryListener(forId id: String) {
        guard let currentQuery = queries[id] else {
            return
        }
        
        currentQuery.removeAllObservers()
    }
}

// MARK: Chat changes listening
extension ChatsListener {
    private func listenForChatChanges(chat: Chat) {
        let chatIdQueryKey = "\(chat.id)_changes"
        removeQueryListener(forId: chatIdQueryKey)
        
        let ref = Database.database().reference()
        let chatsChild: DatabaseReference = ref.child("chats/\(chat.id)")
        let query = chatsChild.queryOrderedByKey()
        query.observe(.childChanged) { (snapshot) in
            guard
                let value = snapshot.value,
                let chatValue = ChatValue(key: snapshot.key, value: value)
            else {
                return
            }
            
            let change = ChatValueChange(chatId: chat.id, chatValue: chatValue)
            self.didChange?(.chatUpdated(change))
        }
        
        queries[chatIdQueryKey] = query
    }
}
