//
//  AuthLoadingViewModel.swift
//  Speezy
//
//  Created by Matt Beaney on 05/01/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import FirebaseAuth

class AuthLoadingViewModel {
    
    private var listener: AuthStateDidChangeListenerHandle?
    private var tokenSyncService = PushTokenSyncService()
    
    func checkAuthStatus(completion: @escaping (User?) -> Void) {
        
        var timerCompleted = false
        var authCompleted = false
        var storedUser: User?
        
        DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + 1.0) {
            timerCompleted = true
            
            if authCompleted {
                completion(storedUser)
            }
        }
        
        listener = Auth.auth().addStateDidChangeListener { (auth, user) in
            authCompleted = true
            
            if let userId = user?.uid {
                Store.shared.listenForChatChanges(userId: userId)
                self.tokenSyncService.syncPushToken(userId: userId)
            }
            
            if timerCompleted {
                completion(user)
            } else {
                storedUser = user
            }
        }
    }
    
    func stopListening() {
        guard let listener = self.listener else {
            return
        }
        
        Auth.auth().removeStateDidChangeListener(listener)
    }
}
