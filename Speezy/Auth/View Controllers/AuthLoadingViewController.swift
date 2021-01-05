//
//  AuthLoadingViewController.swift
//  Speezy
//
//  Created by Matt Beaney on 05/01/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import UIKit
import FirebaseAuth

protocol AuthLoadingViewControllerDelegate: AnyObject {
    func authLoadingViewControllerNotSignedIn(_ viewController: AuthLoadingViewController)
    func authLoadingViewController(
        _ viewController: AuthLoadingViewController,
        signedInWithUser: User
    )
}

class AuthLoadingViewController: UIViewController {
    @IBOutlet weak var loadingSpinner: UIActivityIndicatorView!
    
    weak var delegate: AuthLoadingViewControllerDelegate?
    
    let viewModel = AuthLoadingViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadingSpinner.startAnimating()
        viewModel.checkAuthStatus { (user) in
            DispatchQueue.main.async {
                if let user = user {
                    self.delegate?.authLoadingViewController(
                        self,
                        signedInWithUser: user
                    )
                } else {
                    self.delegate?.authLoadingViewControllerNotSignedIn(self)
                }
            }
        }
    }
}
