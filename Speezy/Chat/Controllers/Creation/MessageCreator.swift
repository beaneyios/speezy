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
            let newMessageChild = chatChild.childByAutoId()
            
            if let key = newMessageChild.key {
                updatePaths["messages/\($0.id)/\(key)"] = messageDict
            }
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
