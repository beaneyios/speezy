//
//  DatabaseChatParser.swift
//  Speezy
//
//  Created by Matt Beaney on 23/01/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation

class ChatParser {
    static func parseChat(key: String, dict: NSDictionary) -> Chat? {
        guard
            let lastUpdated = dict["last_updated"] as? TimeInterval,
            let title = dict["title"] as? String,
            let lastMessage = dict["last_message"] as? String
        else {
            return nil
        }
        
        let readBy = dict["read_by"] as? [String: TimeInterval]
        
        let chat = Chat(
            id: key,
            title: title,
            lastUpdated: lastUpdated,
            lastMessage: lastMessage,
            chatImageUrl: URL(key: "chat_image_url", dict: dict),
            readBy: readBy ?? [:],
            displayNames: dict["display_names"] as? [String: String],
            profileImages: dict["profile_images"] as? [String: String]
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
        
        return Chatter(
            id: key,
            displayName: displayName,
            profileImageUrl: URL(key: "profile_image_url", dict: dict),
            pushToken: dict["push_token"] as? String
        )
    }
    
    static func parseMessage(
        chat: Chat,
        chatters: [Chatter],
        key: String,
        dict: NSDictionary
    ) -> Message? {
        guard
            let userId = dict["user_id"] as? String,
            let chatter = chatters.chatter(for: userId),
            let sentDateSeconds = dict["sent_date"] as? TimeInterval
        else {
            return nil
        }
        
        let readBy = chatters.readChatters(
            forMessageDate: Date(timeIntervalSince1970: sentDateSeconds),
            chat: chat
        )
        
        return Message(
            id: key,
            chatter: chatter,
            sent: Date(timeIntervalSince1970: sentDateSeconds),
            message: dict["message"] as? String,
            audioId: dict["audio_id"] as? String,
            audioUrl: URL(key: "audio_url", dict: dict),
            attachmentUrl: URL(key: "attachment_url", dict: dict),
            duration: dict["duration"] as? TimeInterval,
            readBy: readBy
        )
    }
}
