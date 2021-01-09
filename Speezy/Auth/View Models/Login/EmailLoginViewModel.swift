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
    
    func login(completion: @escaping (Result<User, Error>) -> Void) {
        guard !email.isEmpty && !password.isEmpty else {
            assertionFailure("These should have been validated earlier on")
            return
        }
        
        Auth.auth().signIn(withEmail: email, password: password) { (result, error) in
            if let user = result?.user {
                completion(.success(user))
            } else if let error = error {
                completion(.failure(error))
            } else {
                // TODO: Handle no error
            }
        }
    }
}

extension EmailLoginViewModel {    
    func validatonError() -> ValidationError? {
        if email.isEmpty {
            return ValidationError(
                title: "No email address supplied",
                message: "Please ensure you enter a valid email address"
            )
        }
        
        if password.isEmpty {
            return ValidationError(
                title: "No password supplied",
                message: "Please ensure you enter a password"
            )
        }
        
        return nil
    }
}

