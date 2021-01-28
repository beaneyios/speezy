//
//  DatabaseChatUserUpdater.swift
//  Speezy
//
//  Created by Matt Beaney on 28/01/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation
import FirebaseDatabase

class ChatUserUpdater {
    func updateUserChatLists(
        with chat: Chat,
        completion: @escaping (Result<Chat, Error>) -> Void
    ) {
        let ref = Database.database().reference()
        let group = DispatchGroup()
        chat.chatters.forEach {
            group.enter()
            
            let userChild = ref.child("users/\($0.id)/chats/\(chat.id)")
            userChild.setValue(true) { (error, ref) in
                // TODO: Consider how to handle errors here.
                group.leave()
            }
        }
        
        group.notify(queue: DispatchQueue.global()) {
            completion(.success(chat))
        }
    }
}
