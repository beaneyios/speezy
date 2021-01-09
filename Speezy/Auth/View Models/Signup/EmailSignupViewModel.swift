//
//  AuthViewModel.swift
//  Speezy
//
//  Created by Matt Beaney on 23/12/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import Foundation
import FirebaseAuth

class EmailSignupViewModel: FirebaseSignupViewModel {
    var email: String = ""
    var password: String = ""
    var verifyPassword: String = ""    
    var profile: Profile = Profile()
    
    var profileImageAttachment: UIImage?
    
    func createProfile(completion: @escaping () -> Void) {
        guard !email.isEmpty && !password.isEmpty else {
            assertionFailure("These should have been validated earlier on")
            return
        }
        
        Auth.auth().createUser(withEmail: email, password: password) { (result, error) in
            if let user = result?.user {
                self.createProfileInFireStore(
                    userId: user.uid,
                    completion: completion
                )
            } else if let error = error {
                // TODO: Handle error
            } else {
                // TODO: Handle no error
            }
        }  
    }
    
    private func createProfileInFireStore(userId: String, completion: @escaping () -> Void) {
        FirebaseUserProfileEditor().updateUserProfile(
            userId: userId,
            profile: profile,
            profileImage: profileImageAttachment,
            completion: completion
        )
    }
}

extension EmailSignupViewModel {
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
        
        if password.count < 6 {
            return ValidationError(
                title: "Password too short",
                message: "Password must be at least 6 characters"
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
