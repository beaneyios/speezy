//
//  DatabaseMessageParser.swift
//  Speezy
//
//  Created by Matt Beaney on 22/01/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation

class DatabaseMessageParser {
    static func parseMessage(chat: Chat, key: String, dict: NSDictionary) -> Message? {
        guard
            let userId = dict["user_id"] as? String,
            let chatter = chat.chatters.chatter(for: userId),
            let sentDateSeconds = dict["sent_date"] as? TimeInterval
        else {
            return nil
        }
        
        return Message(
            id: key,
            chatter: chatter,
            sent: Date(timeIntervalSince1970: sentDateSeconds),
            message: dict["message"] as? String,
            audioId: dict["audio_id"] as? String,
            audioUrl: URL(key: "audio_url", dict: dict),
            attachmentUrl: URL(key: "attachment_url", dict: dict),
            duration: dict["duration"] as? TimeInterval,
            readBy: []
        )
    }
}
