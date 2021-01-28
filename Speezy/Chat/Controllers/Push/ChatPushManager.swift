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
    func sendNotification(message: String, chat: Chat) {
        let tokens = chat.chatters.compactMap {
            $0.pushToken
        }
        
        let functions = Functions.functions()

        let infoDict: [String: Any] = [
            "tokens": tokens,
            "title": "\(chat.title)",
            "body": "\(message)"
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
}
