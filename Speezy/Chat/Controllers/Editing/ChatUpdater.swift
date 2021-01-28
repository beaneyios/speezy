//
//  DatabaseChatUpdater.swift
//  Speezy
//
//  Created by Matt Beaney on 28/01/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation
import FirebaseDatabase

class ChatUpdater {
    func updateChat(
        chat: Chat,
        completion: @escaping (Result<Chat, Error>) -> Void
    ) {
        let ref = Database.database().reference()
        let groupChild = ref.child("chats/\(chat.id)")
        groupChild.setValue(chat.toDict) { (error, ref) in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            completion(.success(chat))
        }
    }
}
