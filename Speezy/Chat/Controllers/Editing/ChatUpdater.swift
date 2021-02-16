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
        chatValue: ChatValue,
        chatId: String
    ) {
        let ref = Database.database().reference()
        let groupChild = ref.child("chats/\(chatId)/\(chatValue.key)")
        groupChild.setValue(chatValue.value)
    }
}
