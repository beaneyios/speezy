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
    
    func login(completion: @escaping (AuthResult) -> Void) {
        guard !email.isEmpty && !password.isEmpty else {
            assertionFailure("These should have been validated earlier on")
            return
        }
        
        Auth.auth().signIn(withEmail: email, password: password) { (result, error) in
            if let user = result?.user {
                completion(.success)
            } else {
                let error = AuthErrorFactory.authError(for: error)
                completion(.failure(error))
            }
        }
    }
}

extension EmailLoginViewModel {    
    func validationError() -> AuthError? {
        if email.isEmpty {
            return AuthError(
                message: "No email address supplied",
                field: .email
            )
        }
        
        if password.isEmpty {
            return AuthError(
                message: "Please ensure you enter a password",
                field: .password
            )
        }
        
        return nil
    }
}

