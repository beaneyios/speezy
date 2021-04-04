//
//  ForgotPasswordViewModel.swift
//  Speezy
//
//  Created by Matt Beaney on 14/03/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation
import FirebaseAuth

class ForgotPasswordViewModel {
    var email: String = ""
    
    func validationError() -> FormError? {
        if email.isEmpty {
            return FormError(
                message: "Please ensure you enter a valid email address",
                field: Field.email
            )
        }
        
        if !EmailValidator.isValidEmail(email) {
            return FormError(
                message: "Please ensure you enter a valid email address",
                field: Field.email
            )
        }
        
        return nil
    }
    
    func submit(completion: @escaping (FormError?) -> Void) {
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let error = error {
                let formError = FormError(message: error.localizedDescription, field: .email)
                completion(formError)
            } else {
                completion(nil)
            }
        }
    }
}
