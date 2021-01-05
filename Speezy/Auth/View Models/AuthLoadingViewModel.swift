//
//  AuthLoadingViewModel.swift
//  Speezy
//
//  Created by Matt Beaney on 05/01/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import FirebaseAuth

class AuthLoadingViewModel {
    func checkAuthStatus(completion: @escaping (User?) -> Void) {
        
        var timerCompleted = false
        var authCompleted = false
        var storedUser: User?
        
        DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + 1.5) {
            timerCompleted = true
            
            if authCompleted {
                completion(storedUser)
            }
        }
        
        Auth.auth().addStateDidChangeListener { (auth, user) in
            authCompleted = true
            
            if timerCompleted {
                completion(user)
            } else {
                storedUser = user
            }
        }
    }
}
