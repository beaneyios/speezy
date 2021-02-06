//
//  ChatValue.swift
//  Speezy
//
//  Created by Matt Beaney on 30/01/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation

struct ChatValueChange {
    let chatId: String
    let chatValue: ChatValue
}

enum ChatValue {
    case lastMessage(String)
    case lastUpdated(TimeInterval)
    case title(String)
    case readBy(String)
    
    init?(key: String, value: Any) {
        if key == "last_updated", let lastUpdated = value as? TimeInterval {
            self = .lastUpdated(lastUpdated)
        } else if key == "last_message", let lastMessage = value as? String {
            self = .lastMessage(lastMessage)
        } else if key == "title", let title = value as? String {
            self = .title(title)
        } else if key == "read_by", let readBy = value as? String {
            self = .readBy(readBy)
        } else {
            return nil
        }
    }
}
