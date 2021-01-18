//
//  AuthError.swift
//  Speezy
//
//  Created by Matt Beaney on 10/01/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation

enum Field: Hashable {
    case email
    case password
    case passwordVerifier
    case username
}

struct AuthError {
    var message: String
    var field: Field?
}