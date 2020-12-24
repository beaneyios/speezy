//
//  AuthViewModel.swift
//  Speezy
//
//  Created by Matt Beaney on 23/12/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import Foundation
import FirebaseAuth

class SignupViewModel {
    var email: String = ""
    var password: String = ""
    var verifyPassword: String = ""
    var name: String = ""
    var aboutYou: String = ""
    
    func signup(completion: @escaping (Result<User, Error>) -> Void) {
        guard !email.isEmpty && !password.isEmpty else {
            assertionFailure("These should have been validated earlier on")
            return
        }
        
        Auth.auth().createUser(withEmail: email, password: password) { (result, error) in
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

extension SignupViewModel {
    struct ValidationError {
        var title: String
        var message: String
    }
    
    func validatonError() -> ValidationError? {
        if email.isEmpty {
            return ValidationError(
                title: "No email address supplied",
                message: "Please ensure you enter a valid email address"
            )
        }
        
        if !isValidEmail(email) {
            return ValidationError(
                title: "Email address invalid",
                message: "Please ensure you enter a valid email address"
            )
        }
        
        if password.isEmpty {
            return ValidationError(
                title: "No password supplied",
                message: "Please ensure you enter a password"
            )
        }
        
        if password != verifyPassword {
            return ValidationError(
                title: "Passwords do not match",
                message: "Please check your passwords."
            )
        }
        
        return nil
    }
    
    func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"

        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
}
