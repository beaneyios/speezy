//
//  AuthViewModel.swift
//  Speezy
//
//  Created by Matt Beaney on 23/12/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import Foundation

class SignupViewModel {
    var email: String = ""
    var password: String = ""
    var verifyPassword: String = ""
    var name: String = ""
    var aboutYou: String = ""
    
    
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
