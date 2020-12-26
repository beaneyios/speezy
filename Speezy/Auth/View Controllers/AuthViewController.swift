//
//  AuthViewController.swift
//  Speezy
//
//  Created by Matt Beaney on 23/12/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import UIKit
import FirebaseAuth

protocol AuthViewControllerDelegate: AnyObject {
    func authViewController(
        _ viewController: AuthViewController,
        didCompleteSignupWithUser user: User
    )
    func authViewControllerdidSelectSignupWithEmail(_ viewController: AuthViewController)
}

class AuthViewController: UIViewController {
    
    @IBOutlet weak var btnSignupWithEmail: UIButton!
    @IBOutlet weak var btnSignupWithEmailContainer: UIView!
    
    weak var delegate: AuthViewControllerDelegate?
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        btnSignupWithEmailContainer.layer.cornerRadius = btnSignupWithEmailContainer.frame.height / 2.0
        btnSignupWithEmailContainer.clipsToBounds = true
    }
    
    @IBAction func signUpWithEmail(_ sender: Any) {
        delegate?.authViewControllerdidSelectSignupWithEmail(self)
    }
    
    @IBAction func signUpWithFacebook(_ sender: Any) {
        let viewModel = FacebookSignupViewModel()
        viewModel.login(viewController: self) { result in
            DispatchQueue.main.async {
                switch result {
                case let .success(user):
                    self.delegate?.authViewController(
                        self,
                        didCompleteSignupWithUser: user
                    )
                case let .failure(error):
                    break
                }
            }
        }
    }
    
    @IBAction func signUpWithApple(_ sender: Any) {
        guard let window = view.window else {
            assertionFailure("No window to anchor.")
            return
        }
        
        let viewModel = AppleSignupViewModel(anchor: window)
        viewModel.didChange = { change in
            DispatchQueue.main.async {
                switch change {
                case let .loggedIn(user):
                    self.delegate?.authViewController(
                        self,
                        didCompleteSignupWithUser: user
                    )
                }
            }
        }
        
        viewModel.startSignInWithAppleFlow()
    }
    
    @IBAction func signIn(_ sender: Any) {
    }
}
