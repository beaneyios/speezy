//
//  MessageReply.swift
//  Speezy
//
//  Created by Matt Beaney on 18/04/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation

struct MessageReply: Equatable, Identifiable {
    var id: String
    var chatter: Chatter
    var sent: Date
    var message: String?
    var audioId: String?
    var duration: TimeInterval?
    
    static func fromDict(
        _ dict: NSDictionary,
        chat: Chat,
        chatters: [Chatter]
    ) -> MessageReply? {
        guard
            let userId = dict["user_id"] as? String,
            let sentDateSeconds = dict["sent_date"] as? TimeInterval
        else {
            return nil
        }
        
        let chatter = chatters.chatter(for: userId) ?? Chatter(
            id: "No ID",
            displayName: "Not found",
            profileImageUrl: nil,
            pushToken: nil
        )
        
        return MessageReply(
            id: userId,
            chatter: chatter,
            sent: Date(timeIntervalSince1970: sentDateSeconds),
            message: dict["message"] as? String,
            audioId: dict["audio_id"] as? String,
            duration: dict["duration"] as? TimeInterval
        )
    }
    
    var toDict: [String: Any] {
        var messageDict: [String: Any] = [
            "sent_date": sent.timeIntervalSince1970
        ]
        
        if let messageText = message {
            messageDict["message"] = messageText
        }
        
        if let audioId = audioId {
            messageDict["audio_id"] = audioId
        }
        
        if let duration = duration {
            messageDict["duration"] = duration
        }
        
        messageDict["user_id"] = chatter.id
        return messageDict
    }
}
