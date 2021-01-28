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
    typealias PushTokenUnsyncHandler = (Error?) -> Void
    
    func syncPushToken(
        forUserId userId: String,
        token: String,
        completion: PushTokenSyncHandler?
    ) {
        let ref = Database.database().reference()
        let userRef = ref.child("users/\(userId)/profile/push_token")
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
    
    func unsyncPushToken(
        forUserId userId: String,
        completion: PushTokenUnsyncHandler?
    ) {
        let ref = Database.database().reference()
        let userRef = ref.child("users/\(userId)/profile/push_token")
        userRef.removeValue { (error, ref) in
            if let error = error {
                completion?(error)
                return
            }
            
            self.unsyncPushTokenFromGroups(
                userId: userId,
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
    
    private func unsyncPushTokenFromGroups(
        userId: String,
        completion: PushTokenUnsyncHandler?
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
                chatterRef.removeValue { (error, ref) in
                    if let error = error {
                        completion?(error)
                        return
                    }
                    
                    completion?(nil)
                }
            }
        }
    }
}

extension DatabasePushTokenManager {
    func fetchTokens(
        for ids: [String],
        completion: @escaping (Result<[UserToken], Error>) -> Void
    ) {
        let group = DispatchGroup()
        var userTokens = [UserToken]()
        
        let ref = Database.database().reference()
        ids.forEach {
            let userId = $0
            let userChild = ref.child("users/\($0)/push_token")
            
            group.enter()
            userChild.observeSingleEvent(of: .value) { (snapshot) in
                guard let token = snapshot.value as? String else {
                    group.leave()
                    return
                }
                
                userTokens.append(UserToken(userId: userId, token: token))
                group.leave()
            }
        }
        
        group.notify(queue: .global()) {
            completion(.success(userTokens))
        }
    }
}
