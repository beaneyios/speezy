//
//  DatabaseChatParser.swift
//  Speezy
//
//  Created by Matt Beaney on 23/01/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import UIKit

class ChatParser {
    static func parseChat(key: String, dict: NSDictionary) -> Chat? {
        guard
            let lastUpdated = dict["last_updated"] as? TimeInterval,
            let title = dict["title"] as? String,
            let lastMessage = dict["last_message"] as? String,
            let chattersDict = dict["chatters"] as? NSDictionary
        else {
            return nil
        }
        
        let readBy = dict["read_by"] as? [String: TimeInterval]
        let pushTokensDict = dict["push_tokens"] as? [String: String]
        let pushTokens = [UserToken](dict: pushTokensDict)
        let ownerId = dict["owner_id"] as? String
        
        let chat = Chat(
            id: key,
            title: title,
            lastUpdated: lastUpdated,
            lastMessage: lastMessage,
            chatImageUrl: URL(key: "chat_image_url", dict: dict),
            readBy: readBy ?? [:],
            pushTokens: pushTokens,
            chatters: parseChatters(dict: chattersDict),
            ownerId: ownerId
        )
        
        return chat
    }
    
    static func parseChatters(dict: NSDictionary) -> [Chatter] {
        dict.compactMap {
            guard let key = $0.key as? String, let dict = $0.value as? NSDictionary else {
                return nil
            }
            
            return self.parseChatter(key: key, dict: dict)
        }
    }
    
    static func parseChatter(key: String, dict: NSDictionary?) -> Chatter? {
        guard
            let dict = dict,
            let displayName = dict["display_name"] as? String
        else {
            return nil
        }
        
        let color: UIColor = {
            guard let colorString = dict["color"] as? String else {
                return UIColor.random
            }
            
            return UIColor(hex: colorString) ?? UIColor.random
        }()
        
        return Chatter(
            id: key,
            displayName: displayName,
            profileImageUrl: URL(key: "profile_image_url", dict: dict),
            color: color
        )
    }
}
