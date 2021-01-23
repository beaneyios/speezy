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
    
    func createProfile(completion: @escaping (AuthResult) -> Void) {
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
            } else {
                let error = AuthErrorFactory.authError(for: error)
                completion(.failure(error))
            }
        }  
    }
    
    private func createProfileInFireStore(userId: String, completion: @escaping (AuthResult) -> Void) {
        DatabaseProfileManager().updateUserProfile(
            userId: userId,
            profile: profile,
            profileImage: profileImageAttachment,
            completion: completion
        )
    }
}

extension EmailSignupViewModel {    
    func validationError() -> FormError? {
        if email.isEmpty {
            return FormError(
                message: "Please ensure you enter a valid email address",
                field: Field.email
            )
        }
        
        if !isValidEmail(email) {
            return FormError(
                message: "Please ensure you enter a valid email address",
                field: Field.email
            )
        }
        
        if password.isEmpty {
            return FormError(
                message: "Please ensure you enter a password",
                field: Field.password
            )
        }
        
        if password.count < 6 {
            return FormError(
                message: "Password must be at least 6 characters",
                field: Field.password
            )
        }
        
        if password != verifyPassword {
            return FormError(
                message: "Passwords do not match",
                field: Field.passwordVerifier
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
