//
//  Chat.swift
//  Speezy
//
//  Created by Matt Beaney on 18/01/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation

struct Chat: Equatable, Identifiable {    
    let id: String
    let chatters: [Chatter]
    let readBy: [ReadBy]
    let title: String
    let lastUpdated: TimeInterval
    let lastMessage: String
    let chatImageUrl: URL?
}

extension Array where Element == ReadBy {
    init(string: String) {
        let readBy = string.components(separatedBy: ",")
        self = readBy.compactMap {
            ReadBy(string: $0)
        }
    }
    
    var toString: String {
        map { $0.toString }.joined(separator: ",")
    }
}

extension Chat {
    func withReadBy(userId: String, time: TimeInterval) -> Chat {
        let newReadBy = ReadBy(id: userId, time: time)
        
        return Chat(
            id: id,
            chatters: chatters,
            readBy: readBy.inserting(newReadBy),
            title: title,
            lastUpdated: lastUpdated,
            lastMessage: lastMessage,
            chatImageUrl: chatImageUrl
        )
    }
    
    func withReadBy(readBy: [ReadBy]) -> Chat {
        return Chat(
            id: id,
            chatters: chatters,
            readBy: readBy,
            title: title,
            lastUpdated: lastUpdated,
            lastMessage: lastMessage,
            chatImageUrl: chatImageUrl
        )
    }
    
    func withChatters(chatters: [Chatter]) -> Chat {
        Chat(
            id: id,
            chatters: chatters,
            readBy: readBy,
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
            readBy: readBy,
            title: title,
            lastUpdated: lastUpdated,
            lastMessage: lastMessage,
            chatImageUrl: url
        )
    }
    
    func withLastMessage(_ lastMessage: String) -> Chat {
        Chat(
            id: id,
            chatters: chatters,
            readBy: readBy,
            title: title,
            lastUpdated: lastUpdated,
            lastMessage: lastMessage,
            chatImageUrl: chatImageUrl
        )
    }
    
    func withLastUpdated(_ lastUpdated: TimeInterval) -> Chat {
        Chat(
            id: id,
            chatters: chatters,
            readBy: readBy,
            title: title,
            lastUpdated: lastUpdated,
            lastMessage: lastMessage,
            chatImageUrl: chatImageUrl
        )
    }
    
    func withTitle(_ title: String) -> Chat {
        Chat(
            id: id,
            chatters: chatters,
            readBy: readBy,
            title: title,
            lastUpdated: lastUpdated,
            lastMessage: lastMessage,
            chatImageUrl: chatImageUrl
        )
    }
}

extension Chat {
    var toDict: [String: Any] {
        var dict: [String: Any] = [
            "last_message": lastMessage,
            "last_updated": lastUpdated,
            "read_by": readBy.toString,
            "title": title
        ]
        
        if let chatImageUrl = chatImageUrl {
            dict["chat_image_url"] = chatImageUrl.absoluteString
        }
        
        return dict
    }
}

extension Array where Element == Chat {    
    func containsUnread(userId: String) -> Bool {
        contains {
            !$0.readBy.contains(elementWithId: userId)
        }
    }
}
