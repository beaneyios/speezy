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
    func updateReadBy(
        chatId: String,
        userId: String,
        time: TimeInterval
    ) {
        let ref = Database.database().reference()
        let groupChild = ref.child("chats/\(chatId)/read_by/\(userId)")
        groupChild.setValue(time)
    }
}
