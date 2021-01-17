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

struct Chatter {
    let id: String
    let displayName: String
    let profileImage: UIImage
}

struct Chat {
    let id: String
    let chatters: [Chatter]
    let title: String
}

extension Array where Element == Chatter {
    func chatter(for id: String) -> Chatter? {
        first { $0.id == id }
    }
}

struct Message {
    let chatter: Chatter
    let sent: Date
    
    let message: String?
    let audioUrl: URL?
    let attachmentUrl: URL?
    let duration: TimeInterval?
    
    let readBy: [Chatter]
}

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
}
