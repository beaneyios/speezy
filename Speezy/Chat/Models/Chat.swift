//
//  Chat.swift
//  Speezy
//
//  Created by Matt Beaney on 18/01/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation

struct Chat: Identifiable, Hashable {
    let id: String
    let title: String
    let lastUpdated: TimeInterval
    let lastMessage: String
    let chatImageUrl: URL?
    let readBy: [String: TimeInterval]
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
}

extension Chat {
    func withReadBy(readBy: [String: TimeInterval]) -> Chat {
        var newReadBy = self.readBy
        
        readBy.keys.forEach {
            newReadBy[$0] = readBy[$0]
        }

        return Chat(
            id: id,
            title: title,
            lastUpdated: lastUpdated,
            lastMessage: lastMessage,
            chatImageUrl: chatImageUrl,
            readBy: newReadBy
        )
    }
    
    func withChatImageUrl(_ url: URL) -> Chat {
        Chat(
            id: id,
            title: title,
            lastUpdated: lastUpdated,
            lastMessage: lastMessage,
            chatImageUrl: url,
            readBy: readBy
        )
    }
    
    func withLastMessage(_ lastMessage: String) -> Chat {
        Chat(
            id: id,
            title: title,
            lastUpdated: lastUpdated,
            lastMessage: lastMessage,
            chatImageUrl: chatImageUrl,
            readBy: readBy
        )
    }
    
    func withLastUpdated(_ lastUpdated: TimeInterval) -> Chat {
        Chat(
            id: id,
            title: title,
            lastUpdated: lastUpdated,
            lastMessage: lastMessage,
            chatImageUrl: chatImageUrl,
            readBy: readBy
        )
    }
    
    func withTitle(_ title: String) -> Chat {
        Chat(
            id: id,
            title: title,
            lastUpdated: lastUpdated,
            lastMessage: lastMessage,
            chatImageUrl: chatImageUrl,
            readBy: readBy
        )
    }
}

extension Chat {
    var toDict: [String: Any] {
        var dict: [String: Any] = [
            "last_message": lastMessage,
            "last_updated": lastUpdated,
            "title": title,
            "read_by": readBy
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
            
            let chat = $0
            
            guard let lastRead = chat.readBy[userId] else {
                return true
            }
            
            if lastRead < chat.lastUpdated {
                return true
            } else {
                return false
            }
        }
    }
    
    func sortedByLastUpdated() -> Self {
        sorted(by: { (chat1, chat2) -> Bool in
            chat1.lastUpdated > chat2.lastUpdated
        })
    }
}
