//
//  Chat.swift
//  Speezy
//
//  Created by Matt Beaney on 18/01/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation

struct Chat: Identifiable, Hashable {
    var id: String
    var title: String
    var lastUpdated: TimeInterval
    var lastMessage: String
    var chatImageUrl: URL?
    var readBy: [String: TimeInterval]
    var chatters: [Chatter]
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
}

extension Chat {
    func computedTitle(currentUserId: String?) -> String {
        if title == ChatCreator.dynamicTitleKey {
            return title(currentUserId: currentUserId)
        }
        
        return title
    }
    
    func title(currentUserId: String?) -> String {
        guard title == ChatCreator.dynamicTitleKey else {
            return title
        }
        
        if let currentUserId = currentUserId {
            if chatters.count > 2 {
                return groupChatterString(
                    chatters: chatters,
                    currentUserId: currentUserId
                )
            } else {
                return singleChatterString(
                    chatters: chatters,
                    currentUserId: currentUserId
                )
            }
        } else {
            return "No group title"
        }
    }
    
    private func groupChatterString(chatters: [Chatter], currentUserId: String) -> String {
        let chatterString = chatters.filter {
            $0.id != currentUserId
        }.map {
            $0.displayName
        }.joined(separator: ", ")
        
        return "Group with \(chatterString)"
    }
    
    private func singleChatterString(chatters: [Chatter], currentUserId: String) -> String {
        let matchedChatter = chatters.first {
            $0.id != currentUserId
        }
        
        if let matchedChatter = matchedChatter {
            return matchedChatter.displayName
        } else {
            return "No group title"
        }
    }
}

extension Chat {
    func withReadBy(readBy: [String: TimeInterval]) -> Chat {
        var newChat = self
        var newReadBy = self.readBy
        
        readBy.keys.forEach {
            newReadBy[$0] = readBy[$0]
        }
        
        newChat.readBy = newReadBy
        return newChat
    }
    
    func withChatImageUrl(_ url: URL) -> Chat {
        var newChat = self
        newChat.chatImageUrl = url
        return newChat
    }
    
    func withLastMessage(_ lastMessage: String) -> Chat {
        var newChat = self
        newChat.lastMessage = lastMessage
        return newChat
    }
    
    func withLastUpdated(_ lastUpdated: TimeInterval) -> Chat {
        var newChat = self
        newChat.lastUpdated = lastUpdated
        return newChat
    }
    
    func withTitle(_ title: String) -> Chat {
        var newChat = self
        newChat.title = title
        return newChat
    }
}

extension Chat {
    var toDict: [String: Any] {
        var dict: [String: Any] = [
            "last_message": lastMessage,
            "last_updated": lastUpdated,
            "title": title,
            "read_by": readBy,
            "chatters": chatters.toDict
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
