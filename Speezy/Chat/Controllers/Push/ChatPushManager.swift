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
        chatters: [Chatter],
        from chatter: Chatter
    ) {
        let tokens = chatters.filter {
            $0 != chatter
        }.compactMap {
            $0.pushToken
        }
        
        let functions = Functions.functions()

        let infoDict: [String: Any] = [
            "tokens": tokens,
            "title": "\(chat.title)",
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
            let chat = $0
            ChattersFetcher().fetchChatters(chat: chat) { (result) in
                switch result {
                case let .success(chatters):
                    self.sendNotification(
                        message: message,
                        chat: chat,
                        chatters: chatters,
                        from: chatter
                    )
                case .failure:
                    break
                }
            }
        }
    }
}
