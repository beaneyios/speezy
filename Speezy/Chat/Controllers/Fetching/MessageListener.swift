//
//  DatabaseChatManager.swift
//  Speezy
//
//  Created by Matt Beaney on 17/01/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation
import FirebaseAuth
import FirebaseDatabase

class MessageListener: Identifiable {
    typealias MessageFetchHandler = (Result<Message, Error>) -> Void
    
    var id: String {
        chat.id
    }
    
    let chat: Chat
    let chatters: [Chatter]
    private var currentNewMessageQuery: DatabaseQuery?
    private var currentDeletedMessageQuery: DatabaseQuery?
    private var queries: [String: DatabaseQuery] = [:]
    
    init(chat: Chat, chatters: [Chatter]) {
        self.chat = chat
        self.chatters = chatters
    }
    
    func listenForNewMessages(
        mostRecentMessage: Message?,
        completion: @escaping MessageFetchHandler
    ) {
        currentNewMessageQuery?.removeAllObservers()
        
        let ref = Database.database().reference()
        let messagesChild: DatabaseReference = ref.child("messages/\(chat.id)")
        currentNewMessageQuery = messagesChild.queryOrderedByKey().queryLimited(toLast: 1)

        currentNewMessageQuery?.observe(.childAdded) { (snapshot) in
            guard let result = snapshot.value as? NSDictionary else {
                // TODO: handle error
                assertionFailure("Snapshot not dictionary")
                return
            }
            
            let message = Message.fromDict(
                dict: result,
                key: snapshot.key,
                chat: self.chat,
                chatters: self.chatters
            )
            
            if let message = message {
                if message != mostRecentMessage {
                    completion(.success(message))
                } else {
                    // Do nothing, we don't want to have duplicated messages.
                }
            } else {
                // TODO: Handle parse failure
                assertionFailure("Parsing failed")
            }
        }
    }
    
    func listenForDeletedMessages(completion: @escaping (Result<String, Error>) -> Void) {
        currentDeletedMessageQuery?.removeAllObservers()
        
        let ref = Database.database().reference()
        let messagesChild: DatabaseReference = ref.child("messages/\(chat.id)")
        currentDeletedMessageQuery = messagesChild.queryOrderedByKey()
        currentDeletedMessageQuery?.observe(.childRemoved) { (snapshot) in
            completion(.success(snapshot.key))
        }
    }
    
    
    
    func stopListening() {
        currentNewMessageQuery?.removeAllObservers()
        currentDeletedMessageQuery?.removeAllObservers()
        
        currentNewMessageQuery = nil
        currentDeletedMessageQuery = nil
    }
}

// MARK: Message changes listening
extension MessageListener {
    func listenForMessageChanges(message: Message, completion: @escaping (MessageValueChange) -> Void) {
        let chatIdQueryKey = "\(message.id)_changes"
        removeQueryListener(forId: chatIdQueryKey)
        
        let ref = Database.database().reference()
        let chatsChild: DatabaseReference = ref.child("messages/\(chat.id)/\(message.id)")
        let query = chatsChild.queryOrderedByKey()
        query.observe(.childChanged) { (snapshot) in
            guard
                let value = snapshot.value,
                let messageValue = MessageValue(key: snapshot.key, value: value)
            else {
                return
            }
            
            let change = MessageValueChange(
                messageId: message.id,
                messageValue: messageValue
            )
            
            completion(change)
        }
        
        queries[chatIdQueryKey] = query
    }
    
    private func removeQueryListener(forId id: String) {
        guard let currentQuery = queries[id] else {
            return
        }
        
        currentQuery.removeAllObservers()
    }
}
