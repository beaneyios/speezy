//
//  MessageFetcher.swift
//  Speezy
//
//  Created by Matt Beaney on 28/01/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation
import FirebaseDatabase

class MessageFetcher {
    func fetchMessages(
        chat: Chat,
        chatters: [Chatter],
        queryCount: UInt,
        mostRecentMessage: Message? = nil,
        completion: @escaping (Result<[Message], Error>) -> Void
    ) {
        let ref = Database.database().reference()
        let chatChild: DatabaseReference = ref.child("messages/\(chat.id)")
        
        let query: DatabaseQuery = {
            if let message = mostRecentMessage {
                return chatChild
                    .queryOrderedByKey()
                    .queryEnding(atValue: message.id)
                    .queryLimited(toLast: 5)
            } else {
                return chatChild.queryOrderedByKey().queryLimited(toLast: queryCount)
            }
        }()
        
        query.observeSingleEvent(of: .value) { (snapshot) in
            guard let result = snapshot.value as? NSDictionary else {
                completion(.success([]))
                return
            }
            
            let messages: [Message] = result.allKeys.compactMap {
                guard
                    let key = $0 as? String,
                    let dict = result[key] as? NSDictionary
                else {
                    return nil
                }
                
                return Message.fromDict(
                    dict: dict,
                    key: key,
                    chat: chat,
                    chatters: chatters
                )
            }.sorted {
                $0.sent > $1.sent
            }.filter {
                $0.id != mostRecentMessage?.id
            }
            
            completion(.success(messages))
        } withCancel: { (error) in
            completion(.failure(error))
        }
    }
}
