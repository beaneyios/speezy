//
//  MessageCreator.swift
//  Speezy
//
//  Created by Matt Beaney on 28/01/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation
import FirebaseDatabase

class MessageCreator {
    func insertMessage(
        item: AudioItem,
        message: Message,
        chat: Chat,
        completion: @escaping (Result<Message, Error>) -> Void
    ) {
        var messageDict: [String: Any] = [
            "audio_id": item.id,
            "duration": item.calculatedDuration,
            "sent_date": message.sent.timeIntervalSince1970
        ]
        
        if let messageText = message.message {
            messageDict["message"] = messageText
        }
        
        if let remoteUrl = item.remoteUrl {
            messageDict["audio_url"] = remoteUrl.absoluteString
        }
        
        if let attachmentUrl = item.attachmentUrl {
            messageDict["attachment_url"] = attachmentUrl
        }
        
        messageDict["user_id"] = message.chatter.id
        
        let ref = Database.database().reference()
        let chatChild = ref.child("messages/\(chat.id)")
        let newMessageChild = chatChild.childByAutoId()
        
        newMessageChild.setValue(messageDict) { (error, newRef) in
            completion(.success(message))
        }
    }
}
