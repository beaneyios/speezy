//
//  ChatCellModel.swift
//  Speezy
//
//  Created by Matt Beaney on 23/01/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import UIKit

struct ChatCellModel {
    let chat: Chat
    
    init(chat: Chat) {
        self.chat = chat
    }
}

extension ChatCellModel {
    var titleText: String {
        chat.title
    }
    
    var lastMessageText: String {
        chat.lastMessage
    }
    
    var lastUpdatedText: String {
        let date = Date(timeIntervalSince1970: chat.lastUpdated)
        return date.relativeTimeString
    }
}
