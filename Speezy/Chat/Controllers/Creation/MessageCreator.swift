//
//  MessageCreator.swift
//  Speezy
//
//  Created by Matt Beaney on 28/01/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation
import FirebaseDatabase

class MessageCreator {
    func insertMessage(
        chats: [Chat],
        message: Message,
        completion: @escaping (Result<Message, Error>) -> Void
    ) {
        let messageDict = message.toDict
        let ref = Database.database().reference()
        var updatePaths: [AnyHashable: Any] = [:]
        
        chats.forEach {
            let chat = $0
            let chatChild = ref.child("messages/\(chat.id)")
            guard let newKey = chatChild.childByAutoId().key else {
                return
            }
            
            let updatedTime = Date().timeIntervalSince1970
            let newMessagePath = "messages/\(chat.id)/\(newKey)"
            updatePaths[newMessagePath] = messageDict
            updatePaths["chats/\(chat.id)/last_updated"] = updatedTime
            updatePaths["chats/\(chat.id)/last_message"] = message.formattedMessage
            updatePaths["chats/\(chat.id)/read_by/\(message.chatter.id)"] = updatedTime
            
            let messageRefPath: String = {
                let root = "user_messages/\(message.chatter.id)/"
                return root + "\(chat.id),\(newKey)"
            }()
            
            updatePaths[messageRefPath] = message.audioId ?? "No_Audio_Id"
        }
        
        ref.updateChildValues(updatePaths) { (error, newRef) in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(message))
            }
        }
    }
}
