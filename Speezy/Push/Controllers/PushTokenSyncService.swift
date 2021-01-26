//
//  PushTokenSyncService.swift
//  Speezy
//
//  Created by Matt Beaney on 26/01/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation
import FirebaseMessaging
import FirebaseAuth

class PushTokenSyncService {
    private let tokenStorageKey = "Speezy_FCM_Token"
    
    // This will run every time the user authorises with Firebase (on launch).
    func syncPushToken(userId: String) {
        // First we should check there is an FCM token.
        guard let fcmToken = Messaging.messaging().fcmToken else {
            return
        }
        
        // If the token is the same since the last
        // time this was called, then we needn't do anything
        // until the user logs out/in.
        if !tokenIsNew(token: fcmToken) {
            return
        }

        updateDatabase(userId: userId, fcmToken: fcmToken)
    }
    
    // This will run every time a new token is returned from FCM.
    func syncPushToken(token: String) {
        if !tokenIsNew(token: token) {
            return
        }
        
        // Is the user logged in - it may well be that this is being
        // called on launch before the user is correctly authorised.
        // So we should terminate now and wait for syncPushToken(userId:)
        // to be called after auth.
        guard let userId = Auth.auth().currentUser?.uid else {
            return
        }
        
        updateDatabase(userId: userId, fcmToken: token)
    }
    
    func unsyncPushToken() {
        guard let userId = Auth.auth().currentUser?.uid else {
            return
        }
        let pushDatabaseManager = DatabasePushTokenManager()
        pushDatabaseManager.unsyncPushToken(
            forUserId: userId,
            completion: nil
        )
    }
    
    private func updateDatabase(userId: String, fcmToken: String) {
        let pushDatabaseManager = DatabasePushTokenManager()
        pushDatabaseManager.syncPushToken(
            forUserId: userId,
            token: fcmToken
        ) { (result) in
            switch result {
            case let .success(token):
                UserDefaults.standard.setValue(token, forKey: self.tokenStorageKey)
            case .failure:
                // We'll try again later.
                break
            }
        }
    }
    
    private func tokenIsNew(token: String) -> Bool {
        guard let storedToken = UserDefaults.standard.string(forKey: tokenStorageKey) else {
            return true
        }
            
        return storedToken == token
    }
}
