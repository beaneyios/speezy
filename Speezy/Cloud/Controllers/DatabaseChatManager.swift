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

class DatabaseChatManager {
    var currentQuery: DatabaseQuery?
    
    func fetchMessages(
        chat: Chat,
        mostRecentMessage: Message? = nil,
        completion: @escaping (Result<[Message], Error>) -> Void
    ) {
        let ref = Database.database().reference()
        let messagesChild: DatabaseReference = ref.child("messages/\(chat.id)")
        
        let query: DatabaseQuery = {
            if let message = mostRecentMessage {
                return messagesChild
                    .queryOrderedByKey()
                    .queryEnding(atValue: message.id)
                    .queryLimited(toLast: 5)
            } else {
                return messagesChild.queryOrderedByKey().queryLimited(toLast: 5)
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
                
                return DatabaseMessageParser.parseMessage(chat: chat, key: key, dict: dict)
            }.sorted {
                $0.sent > $1.sent
            }.filter {
                $0 != mostRecentMessage
            }
            
            completion(.success(messages))
        } withCancel: { (error) in
            completion(.failure(error))
        }
    }
    
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
            
            let message = DatabaseMessageParser.parseMessage(
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
    
    func insertMessage(
        item: AudioItem,
        message: Message,
        chat: Chat,
        completion: @escaping (Result<Message, Error>) -> Void
    ) {
        var messageDict: [String: Any] = [
            "audio_id": item.id,
            "duration": item.calculatedDuration,
            "sent_date": message.sent.timeIntervalSince1970
        ]
        
        if let messageText = message.message {
            messageDict["message"] = messageText
        }
        
        if let remoteUrl = item.remoteUrl {
            messageDict["audio_url"] = remoteUrl.absoluteString
        }
        
        if let attachmentUrl = item.attachmentUrl {
            messageDict["attachment_url"] = attachmentUrl
        }
        
        if let userId = Auth.auth().currentUser?.uid {
            messageDict["user_id"] = userId
        }
        
        let ref = Database.database().reference()
        let chatChild = ref.child("messages/\(chat.id)")
        let newMessageChild = chatChild.childByAutoId()
        newMessageChild.setValue(messageDict) { (error, newRef) in
            completion(.success(message))
        }
    }
}
