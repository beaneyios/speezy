//
//  SignupViewModel.swift
//  Speezy
//
//  Created by Matt Beaney on 30/12/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import Foundation
import FirebaseAuth
import UIKit

protocol FirebaseSignupViewModel: ProfileViewModel {
    func createProfile(completion: @escaping (SpeezyResult<User, FormError?>) -> Void)
    func profileValidationError() -> FormError?
}

extension FirebaseSignupViewModel {
    func profileValidationError() -> FormError? {
        
        if let profile = profile, profile.userName.isEmpty {
            return FormError(
                message: "Please ensure you enter a username, you'll need it for adding contacts.",
                field: Field.username
            )
        }
        
        return nil
    }
}
