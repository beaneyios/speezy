//
//  EmailLoginViewModel.swift
//  Speezy
//
//  Created by Matt Beaney on 09/01/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation
import FirebaseAuth

class EmailLoginViewModel {
    var email: String = ""
    var password: String = ""
    
    let tokenSyncService = PushTokenSyncService()
    
    func login(completion: @escaping (AuthResult) -> Void) {
        guard !email.isEmpty && !password.isEmpty else {
            assertionFailure("These should have been validated earlier on")
            return
        }
        
        Auth.auth().signIn(withEmail: email, password: password) { (result, error) in
            if let user = result?.user {
                completion(.success)
                self.tokenSyncService.syncPushToken(userId: user.uid)
            } else {
                let error = AuthErrorFactory.authError(for: error)
                completion(.failure(error))
            }
        }
    }
}

extension EmailLoginViewModel {    
    func validationError() -> FormError? {
        if email.isEmpty {
            return FormError(
                message: "No email address supplied",
                field: .email
            )
        }
        
        if password.isEmpty {
            return FormError(
                message: "Please ensure you enter a password",
                field: .password
            )
        }
        
        return nil
    }
}

