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

class MessageListener {
    var currentQuery: DatabaseQuery?
    
    func listenForNewMessages(
        mostRecentMessage: Message?,
        chat: Chat,
        completion: @escaping (Result<Message, Error>) -> Void
    ) {
        currentQuery?.removeAllObservers()
        
        let ref = Database.database().reference()
        let messagesChild: DatabaseReference = ref.child("messages/\(chat.id)")
        currentQuery = messagesChild.queryOrderedByKey().queryLimited(toLast: 1)

        currentQuery?.observe(.childAdded) { (snapshot) in
            guard let result = snapshot.value as? NSDictionary else {
                // TODO: handle error
                assertionFailure("Snapshot not dictionary")
                return
            }
            
            let message = ChatParser.parseMessage(
                chat: chat,
                key: snapshot.key,
                dict: result
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
}
