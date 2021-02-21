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
            let chatChild = ref.child("messages/\($0.id)")
            guard let newKey = chatChild.childByAutoId().key else {
                return
            }
            
            let updatedTime = Date().timeIntervalSince1970
            let newMessagePath = "messages/\($0.id)/\(newKey)"
            updatePaths[newMessagePath] = messageDict
            updatePaths["chats/\($0.id)/last_updated"] = updatedTime
            updatePaths["chats/\($0.id)/last_message"] = message.formattedMessage            
            updatePaths["chats/\($0.id)/read_by/\(message.chatter.id)"] = updatedTime
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
