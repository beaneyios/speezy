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
    func fetchMessages(
        chat: Chat,
        completion: @escaping (Result<[Message], Error>) -> Void
    ) {
        let ref = Database.database().reference()
        let messagesChild: DatabaseReference = ref.child("messages/\(chat.id)")
        
        messagesChild.observeSingleEvent(of: .value) { (snapshot) in
            guard let result = snapshot.value as? NSDictionary else {
                completion(.success([]))
                return
            }
            
            let messages: [Message] = result.allKeys.compactMap {
                guard
                    let key = $0 as? String,
                    let dict = result[key] as? NSDictionary,
                    let userId = dict["user_id"] as? String,
                    let chatter = chat.chatters.chatter(for: userId),
                    let sentDateSeconds = dict["sent_date"] as? TimeInterval
                else {
                    return nil
                }
                
                return Message(
                    id: key,
                    chatter: chatter,
                    sent: Date(timeIntervalSince1970: sentDateSeconds),
                    message: dict["message"] as? String,
                    audioUrl: URL(key: "audio_url", dict: dict),
                    attachmentUrl: URL(key: "attachment_url", dict: dict),
                    duration: dict["duration"] as? TimeInterval,
                    readBy: []
                )
            }
            
            completion(.success(messages))
        } withCancel: { (error) in
            completion(.failure(error))
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
        let clipChild = ref.child("messages/\(chat.id)/\(message.id)")
        clipChild.setValue(messageDict) { (error, newRef) in
            completion(.success(message))
        }
    }
}
