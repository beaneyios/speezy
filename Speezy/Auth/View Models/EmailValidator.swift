//
//  EmailValidator.swift
//  Speezy
//
//  Created by Matt Beaney on 14/03/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation

class EmailValidator {
    static func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
}
