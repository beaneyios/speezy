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
        didMoveOnToProfileWithViewModel viewModel: FirebaseSignupViewModel
    )
    
    func authViewController(
        _ viewController: AuthViewController,
        didCompleteSignupWithUser user: User
    )
    
    func authViewControllerdidSelectSignupWithEmail(_ viewController: AuthViewController)
    
    func authViewControllerDidSelectLogin(
        _ viewController: AuthViewController
    )
}

class AuthViewController: UIViewController {
    
    @IBOutlet weak var btnSignupWithEmail: UIButton!
    @IBOutlet weak var btnSignupWithEmailContainer: UIView!
    @IBOutlet weak var facebookSignupBtn: SpeezyButton!
    @IBOutlet weak var appleSignupBtn: SpeezyButton!
    
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
        facebookSignupBtn.startLoading()
        
        let viewModel = FacebookSignupViewModel()
        viewModel.login(viewController: self) {
            DispatchQueue.main.async {
                self.facebookSignupBtn.stopLoading()
                self.delegate?.authViewController(
                    self,
                    didMoveOnToProfileWithViewModel: viewModel
                )
            }
        }
    }
    
    @IBAction func signUpWithApple(_ sender: Any) {
        guard let window = view.window else {
            assertionFailure("No window to anchor.")
            return
        }
        
        appleSignupBtn.startLoading()
        
        let viewModel = AppleSignupViewModel(anchor: window)
        viewModel.didChange = { change in
            DispatchQueue.main.async {
                switch change {
                case let .loggedIn:
                    self.appleSignupBtn.stopLoading()
                    self.delegate?.authViewController(
                        self,
                        didMoveOnToProfileWithViewModel: viewModel
                    )
                }
            }
        }
        
        viewModel.startSignInWithAppleFlow()
    }
    
    @IBAction func signIn(_ sender: Any) {
        delegate?.authViewControllerDidSelectLogin(self)
    }
}
