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
    func sendNotification(message: String, chat: Chat, from chatter: Chatter) {
        let tokens = chat.chatters.filter {
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
            // TODO: Consider how to handle push callbacks.
            
            if let error = error as NSError? {
                if error.domain == FunctionsErrorDomain {
                    let code = FunctionsErrorCode(rawValue: error.code)
                    let message = error.localizedDescription
                    let details = error.userInfo[FunctionsErrorDetailsKey]
                    
                }
            }
            
            print(result?.data)
        }
    }
    
    func sendNotification(message: String, chats: [Chat], from chatter: Chatter) {
        chats.forEach {
            let chat = $0
            if chat.chatters.count > 1 {
                self.sendNotification(message: message, chat: chat, from: chatter)
                return
            }
            
            GroupFetcher().fetchChatters(chat: chat) { (result) in
                switch result {
                case let .success(chatters):
                    let newChat = chat.withChatters(chatters: chatters)
                    self.sendNotification(
                        message: message,
                        chat: newChat,
                        from: chatter
                    )
                case .failure:
                    break
                }
            }
        }
    }
}
