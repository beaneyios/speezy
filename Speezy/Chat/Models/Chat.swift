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
    var displayNames: [String: String]?
    var profileImages: [String: String]?
    var userIds: [String]?
    
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
            if let displayNames = displayNames, let currentUserId = currentUserId {
                let matchedId = displayNames.keys.first {
                    $0 != currentUserId
                }
                
                if let matchedId = matchedId, let displayName = displayNames[matchedId] {
                    return displayName
                } else {
                    return "No group title"
                }
            } else {
                return "No group title"
            }
        }
        
        return title
    }
    
    func youTitle(currentUserId: String?) -> String {
        if title == ChatCreator.dynamicTitleKey {
            if let displayNames = displayNames, let currentUserId = currentUserId {
                let matchedId = displayNames.keys.first {
                    $0 == currentUserId
                }
                
                if let matchedId = matchedId, let displayName = displayNames[matchedId] {
                    return displayName
                } else {
                    return "No group title"
                }
            } else {
                return "No group title"
            }
        }
        
        return title
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
            "read_by": readBy
        ]
        
        if let profileImages = profileImages {
            dict["profile_images"] = profileImages
        }
        
        if let displayNames = displayNames {
            dict["display_names"] = displayNames
        }
        
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
