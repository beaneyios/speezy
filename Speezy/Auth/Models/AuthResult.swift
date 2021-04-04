//
//  AuthResult.swift
//  Speezy
//
//  Created by Matt Beaney on 10/01/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation
import FirebaseAuth

enum AuthResult {
    case success(User)
    case failure(FormError?)
}
