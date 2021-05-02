//
//  Message.swift
//  Speezy
//
//  Created by Matt Beaney on 18/01/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import UIKit

struct Message: Equatable, Identifiable {
    var id: String
    var chatter: Chatter
    var sent: Date
    
    var message: String?
    var audioId: String?
    var audioUrl: URL?
    var attachmentUrl: URL?
    var duration: TimeInterval?
    var readBy: [Chatter]
    var playedBy: [String]
    
    var replyTo: MessageReply?
    
    var formattedMessage: String {
        message ?? "New message from \(chatter.displayName)"
    }
    
    var toReply: MessageReply {
        MessageReply(
            id: id,
            chatter: chatter,
            sent: sent,
            message: message,
            audioId: audioId,
            duration: duration
        )
    }
}

extension Message {
    var toDict: [String: Any] {
        var messageDict: [String: Any] = [
            "sent_date": sent.timeIntervalSince1970
        ]
        
        if let messageText = message {
            messageDict["message"] = messageText
        }
        
        if let audioUrl = audioUrl {
            messageDict["audio_url"] = audioUrl.absoluteString
        }
        
        if let attachmentUrl = attachmentUrl {
            messageDict["attachment_url"] = attachmentUrl
        }
        
        if let audioId = audioId {
            messageDict["audio_id"] = audioId
        }
        
        if let duration = duration {
            messageDict["duration"] = duration
        }
        
        if let replyTo = replyTo {
            messageDict["reply_to"] = replyTo.toDict
        }
        
        messageDict["user_id"] = chatter.id
        messageDict["played_by"] = playedBy.joined(separator: ",")
        return messageDict
    }
    
    static func fromDict(
        dict: NSDictionary,
        key: String,
        chat: Chat,
        chatters: [Chatter]        
    ) -> Message? {
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
            color: UIColor.random
        )
        
        let readBy = chatters.readChatters(
            forMessageDate: Date(timeIntervalSince1970: sentDateSeconds),
            chat: chat
        )
        
        let playedBy: [String] = {
            guard let playedByString = dict["played_by"] as? String else {
                return []
            }
            
            return playedByString.components(separatedBy: ",")
        }()
        
        let replyMessage: MessageReply? = {
            guard let replyToDict = dict["reply_to"] as? NSDictionary else {
                return nil
            }
            
            return MessageReply.fromDict(
                replyToDict,
                chat: chat,
                chatters: chatters
            )
        }()
        
        return Message(
            id: key,
            chatter: chatter,
            sent: Date(timeIntervalSince1970: sentDateSeconds),
            message: dict["message"] as? String,
            audioId: dict["audio_id"] as? String,
            audioUrl: URL(key: "audio_url", dict: dict),
            attachmentUrl: URL(key: "attachment_url", dict: dict),
            duration: dict["duration"] as? TimeInterval,
            readBy: readBy,
            playedBy: playedBy,
            replyTo: replyMessage
        )
    }
}
