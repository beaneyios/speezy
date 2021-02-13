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
            
            // Second thing - listen for any future changes to the chat.
            self.listenForChatChanges(chatId: snapshot.key)
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
            
            self.didChange?(.chatAdded(chat))
        }
    }
    
    private func listenForChatChanges(chatId: String) {
        let chatIdQueryKey = "\(chatId)_changes"
        removeQueryListener(forId: chatIdQueryKey)
        
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
        
        queries[chatIdQueryKey] = query
    }
    
    func stopListening() {
        queries.keys.forEach {
            let chatId = $0
                .replacingOccurrences(of: "_changes", with: "")
                .replacingOccurrences(of: "_additions", with: "")
                .replacingOccurrences(of: "_deletions", with: "")
            self.stopListeningForChatChanges(chatId: chatId)
        }
        
        queries = [:]
    }
    
    private func stopListeningForChatChanges(chatId: String) {
        let chatIdQueryKey = "\(chatId)_changes"
        removeQueryListener(forId: chatIdQueryKey)
    }
    
    private func removeQueryListener(forId id: String) {
        guard let currentQuery = queries[id] else {
            return
        }
        
        currentQuery.removeAllObservers()
    }
}
