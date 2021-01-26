//
//  DatabasePushTokenManager.swift
//  Speezy
//
//  Created by Matt Beaney on 26/01/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation
import FirebaseDatabase

class DatabasePushTokenManager {
    typealias PushTokenSyncHandler = (Result<String, Error>) -> Void
    
    func syncPushToken(
        forUserId userId: String,
        token: String,
        completion: PushTokenSyncHandler?
    ) {
        let ref = Database.database().reference()
        let userRef = ref.child("users/\(userId)/push_token")
        userRef.setValue(token) { (error, ref) in
            if let error = error {
                completion?(.failure(error))
                return
            }
            
            self.syncPushTokenToGroups(
                userId: userId,
                token: token,
                completion: completion
            )
        }
    }
    
    private func syncPushTokenToGroups(
        userId: String,
        token: String,
        completion: PushTokenSyncHandler?
    ) {
        let ref = Database.database().reference()
        let chatListRef = ref.child("users/\(userId)/chats")
        chatListRef.observeSingleEvent(of: .value) { (snapshot) in
            guard let value = snapshot.value as? NSDictionary else {
                return
            }
            
            let chatKeys = value.allKeys
            chatKeys.forEach {
                let chatterRef = ref.child("chatters/\($0)/\(userId)/push_token")
                chatterRef.setValue(token) { (error, ref) in
                    if let error = error {
                        completion?(.failure(error))
                        return
                    }
                    
                    completion?(.success(token))
                }
            }
        }
    }
}
