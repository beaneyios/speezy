//
//  ChatPushManager.swift
//  Speezy
//
//  Created by Matt Beaney on 28/01/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation
import FirebaseDatabase
import FirebaseFunctions

class ChatPushManager {
    func sendNotification(
        message: String,
        chat: Chat,
        from chatter: Chatter
    ) {
        let tokens = chat.pushTokens.filter {
            $0.userId != chatter.id
        }.compactMap {
            $0
        }
        
        let functions = Functions.functions()
        
//        functions.useFunctionsEmulator(origin: "http://localhost:5001")

        let infoDict: [String: Any] = [
            "tokens": tokens,
            "title": "\(chatter.displayName)",
            "body": "\(message)",
            "chatId": chat.id
        ]
        
        functions.httpsCallable("alertNewMessage").call(infoDict) { (result, error) in
            
        }
    }
    
    func sendNotification(
        message: String,
        chats: [Chat],
        from chatter: Chatter
    ) {
        chats.forEach {
            self.sendNotification(
                message: message,
                chat: $0,
                from: chatter
            )
        }
    }
}
