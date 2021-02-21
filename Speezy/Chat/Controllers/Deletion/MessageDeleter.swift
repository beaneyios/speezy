//
//  MessageDeleter.swift
//  Speezy
//
//  Created by Matt Beaney on 21/02/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation
import FirebaseDatabase

class MessageDeleter {
    func deleteMessage(
        message: Message,
        chat: Chat,
        completion: ((Result<Message, Error>) -> Void)? = nil
    ) {
        let ref = Database.database().reference()
        let messageChild = ref.child("messages/\(chat.id)/\(message.id)")
        messageChild.removeValue()
    }
}
