//
//  Message.swift
//  Speezy
//
//  Created by Matt Beaney on 18/01/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation

struct Message: Equatable, Identifiable {
    let id: String
    let chatter: Chatter
    let sent: Date
    
    let message: String?
    let audioId: String?
    let audioUrl: URL?
    let attachmentUrl: URL?
    let duration: TimeInterval?
    
    let readBy: [Chatter]
    
    var formattedMessage: String {
        message ?? "New message from \(chatter.displayName)"
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
        
        messageDict["user_id"] = chatter.id
        return messageDict
    }
}
