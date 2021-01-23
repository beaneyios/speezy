//
//  Chat.swift
//  Speezy
//
//  Created by Matt Beaney on 18/01/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation

struct Chat {
    let id: String
    let chatters: [Chatter]
    let title: String
    let lastUpdated: TimeInterval
    let lastMessage: String
}

extension Chat {
    func withChatters(chatters: [Chatter]) -> Chat {
        Chat(
            id: id,
            chatters: chatters,
            title: title,
            lastUpdated: lastUpdated,
            lastMessage: lastMessage
        )
    }
}
