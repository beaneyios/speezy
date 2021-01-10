//
//  FirebaseErrorFactory.swift
//  Speezy
//
//  Created by Matt Beaney on 10/01/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation

class AuthErrorFactory {
    static func authError(for error: Error?) -> AuthError {
        guard let error = error else {
            return AuthError(
                message: "Something went wrong, please try again",
                field: nil
            )
        }
        
        let userInfo = (error as NSError).userInfo
        guard let description = userInfo[NSLocalizedDescriptionKey] as? String else {
            return AuthError(
                message: "Something went wrong, please try again",
                field: nil
            )
        }
        
        return AuthError(message: description, field: nil)
    }
}
