//
//  AuthViewController.swift
//  Speezy
//
//  Created by Matt Beaney on 23/12/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import UIKit

protocol AuthViewControllerDelegate: AnyObject {
    func authViewControllerdidSelectSignupWithEmail(_ viewController: AuthViewController)
}

class AuthViewController: UIViewController {
    
    @IBOutlet weak var btnSignupWithEmail: UIButton!
    
    weak var delegate: AuthViewControllerDelegate?
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        btnSignupWithEmail.layer.cornerRadius = btnSignupWithEmail.frame.height / 2.0
    }
    
    @IBAction func signUpWithEmail(_ sender: Any) {
        delegate?.authViewControllerdidSelectSignupWithEmail(self)
    }
    
    @IBAction func signUpWithFacebook(_ sender: Any) {
    }
    
    @IBAction func signupWithLinkedIn(_ sender: Any) {
    }
    
    @IBAction func signIn(_ sender: Any) {
    }
}
