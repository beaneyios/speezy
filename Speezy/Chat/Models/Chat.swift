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
    let readBy: [String]
    let title: String
    let lastUpdated: TimeInterval
    let lastMessage: String
    let chatImageUrl: URL?
}

extension Chat {
    func withReadBy(userId: String) -> Chat {
        if readBy.contains(userId) {
            return self
        }
        
        var newReadBy = readBy
        newReadBy.append(userId)
        
        return Chat(
            id: id,
            chatters: chatters,
            readBy: newReadBy,
            title: title,
            lastUpdated: lastUpdated,
            lastMessage: lastMessage,
            chatImageUrl: chatImageUrl
        )
    }
    
    func withReadBy(readBy: [String]) -> Chat {
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
    
    func withLastMessage(_ message: String) -> Chat {
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
            "read_by": readBy.joined(separator: ","),
            "title": title
        ]
        
        if let chatImageUrl = chatImageUrl {
            dict["chat_image_url"] = chatImageUrl.absoluteString
        }
        
        return dict
    }
}

extension Array where Element == Chat {
    func isSameOrderAs(_ array: Self) -> Bool {
        for (index, element) in self.enumerated() {
            if index >= array.count {
                // Something was added, best to assume these aren't in the same order.
                return false
            }
            
            // The chat in this position is not the same chat as self's element.
            let secondElement = array[index]
            if secondElement.id != element.id {
                return false
            }
        }
        
        // No early false terminations, we can assume they are in the same order.
        return true
    }
    
    func containsUnread(userId: String) -> Bool {
        contains {
            !$0.readBy.contains(userId)
        }
    }
}
