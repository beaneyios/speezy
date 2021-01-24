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
    let chatImageUrl: URL?
}

extension Chat {
    func withChatters(chatters: [Chatter]) -> Chat {
        Chat(
            id: id,
            chatters: chatters,
            title: title,
            lastUpdated: lastUpdated,
            lastMessage: lastMessage,
            chatImageUrl: chatImageUrl
        )
    }
    
    func withChatImageUrl(_ url: URL) -> Chat {
        Chat(
            id: id,
            chatters: chatters,
            title: title,
            lastUpdated: lastUpdated,
            lastMessage: lastMessage,
            chatImageUrl: url
        )
    }
}

extension Chat {
    var toDict: [String: Any] {
        var dict: [String: Any] = [
            "last_message": lastMessage,
            "last_updated": lastUpdated,
            "title": title
        ]
        
        if let chatImageUrl = chatImageUrl {
            dict["chat_image_url"] = chatImageUrl.absoluteString
        }
        
        return dict
    }
}
