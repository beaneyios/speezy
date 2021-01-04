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

protocol FirebaseSignupViewModel: AnyObject {
    var profile: Profile { get set }
    var profileImageAttachment: UIImage? { get set }
    func createProfile(completion: @escaping () -> Void)
}
