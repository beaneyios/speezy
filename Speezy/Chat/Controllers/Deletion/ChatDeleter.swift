//
//  ChatDeleter.swift
//  Speezy
//
//  Created by Matt Beaney on 10/02/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation
import FirebaseDatabase

class ChatDeleter {
    func deleteChat(
        chat: Chat,
        chatters: [Chatter],
        userId: String,
        completion: @escaping (Result<Chat, Error>) -> Void
    ) {
        let ref = Database.database().reference()
        
        var updatedData = [
            "users/\(userId)/chats/\(chat.id)": NSNull()
        ]
        
        if chatters.count == 1 && chatters[0].id == userId {
            // This user is the last one left, and they're leaving.
            // So bin the chat.
            updatedData["chats/\(chat.id)"] = NSNull()
            updatedData["chatters/\(chat.id)"] = NSNull()
        } else {
            // Just remove this user.
            updatedData["chatters/\(chat.id)/\(userId)"] = NSNull()
        }
        
        ref.updateChildValues(updatedData) { (error, updatedRef) in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(chat))
            }
        }
    }
}
