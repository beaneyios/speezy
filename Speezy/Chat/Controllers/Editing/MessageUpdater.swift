//
//  MessageUpdater.swift
//  Speezy
//
//  Created by Matt Beaney on 03/04/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation
import FirebaseDatabase

class MessageUpdater {
    func updatePlayed(
        chatId: String,
        userIds: [String],
        messageId: String
    ) {
        let ref = Database.database().reference()
        let groupChild = ref.child("messages/\(chatId)/\(messageId)/played_by")
        groupChild.setValue(userIds.joined(separator: ","))
    }
}
