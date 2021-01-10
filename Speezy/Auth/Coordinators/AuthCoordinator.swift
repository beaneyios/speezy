//
//  AuthCoordinator.swift
//  Speezy
//
//  Created by Matt Beaney on 23/12/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import Foundation
import UIKit
import FirebaseAuth

protocol AuthCoordinatorDelegate: AnyObject {
    func authCoordinatorDidCompleteSignup(_ coordinator: AuthCoordinator)
    func authCoordinatorDidCompleteLogin(_ coordinator: AuthCoordinator)
    func authCoordinatorDidFinish(_ coordinator: AuthCoordinator)
}

class AuthCoordinator: ViewCoordinator {
    let storyboard = UIStoryboard(name: "Auth", bundle: nil)
    let navigationController: UINavigationController
    
    weak var delegate: AuthCoordinatorDelegate?
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    override func start() {
        navigateToAuthLoadingView()
    }
    
    override func finish() {
        delegate?.authCoordinatorDidFinish(self)
    }
    
    private func navigateToAuthLoadingView() {
        let viewController = storyboard.instantiateViewController(
            identifier: "AuthLoadingViewController"
        ) as! AuthLoadingViewController
        viewController.delegate = self
        navigationController.setNavigationBarHidden(true, animated: false)
        navigationController.setViewControllers([viewController], animated: true)
    }
    
    private func navigateToAuthView() {
        let viewController = storyboard.instantiateViewController(identifier: "AuthViewController") as! AuthViewController
        viewController.delegate = self
        navigationController.setNavigationBarHidden(true, animated: false)
        navigationController.setViewControllers([viewController], animated: true)
    }
    
    private func navigateToEmailSignupView() {
        let viewController = storyboard.instantiateViewController(identifier: "EmailSignupViewController") as! EmailSignupViewController
        viewController.delegate = self
        viewController.viewModel = EmailSignupViewModel()
        navigationController.pushViewController(viewController, animated: true)
    }
    
    private func navigateToProfileView(viewModel: FirebaseSignupViewModel) {
        let viewController = storyboard.instantiateViewController(identifier: "ProfileCreationViewController") as! ProfileCreationViewController
        viewController.delegate = self
        viewController.viewModel = viewModel
        navigationController.pushViewController(viewController, animated: true)
    }
    
    private func navigateToLoginView() {
        let viewController = storyboard.instantiateViewController(identifier: "LoginViewController") as! LoginViewController
        viewController.delegate = self
        navigationController.pushViewController(viewController, animated: true)
    }
}

extension AuthCoordinator: AuthLoadingViewControllerDelegate {
    func authLoadingViewControllerNotSignedIn(
        _ viewController: AuthLoadingViewController
    ) {
        navigateToAuthView()
    }
    
    func authLoadingViewController(
        _ viewController: AuthLoadingViewController,
        signedInWithUser: User
    ) {
        delegate?.authCoordinatorDidCompleteSignup(self)
    }
}

extension AuthCoordinator: AuthViewControllerDelegate {
    func authViewControllerDidSelectLogin(_ viewController: AuthViewController) {
        navigateToLoginView()
    }
    
    func authViewController(
        _ viewController: AuthViewController,
        didMoveOnToProfileWithViewModel viewModel: FirebaseSignupViewModel
    ) {
        navigateToProfileView(viewModel: viewModel)
    }
    
    func authViewController(_ viewController: AuthViewController, didCompleteSignupWithUser user: User) {
        delegate?.authCoordinatorDidCompleteSignup(self)
    }
    
    func authViewControllerdidSelectSignupWithEmail(_ viewController: AuthViewController) {
        navigateToEmailSignupView()
    }
}

extension AuthCoordinator: EmailSignupViewControllerDelegate {
    func emailSignupViewController(
        _ viewController: EmailSignupViewController,
        didMoveOnToProfileWithViewModel viewModel: EmailSignupViewModel
    ) {
        navigateToProfileView(viewModel: viewModel)
    }
    
    func emailSignupViewControllerDidGoBack(_ viewController: EmailSignupViewController) {
        navigationController.popViewController(animated: true)
    }
}

extension AuthCoordinator: LoginViewControllerDelegate {
    func loginViewControllerDidLogIn(_ viewController: LoginViewController) {
        delegate?.authCoordinatorDidCompleteLogin(self)
    }
    
    func loginViewControllerDidGoBack(_ viewController: LoginViewController) {
        navigationController.popViewController(animated: true)
    }
}

extension AuthCoordinator: ProfileCreationViewControllerDelegate {
    func profileCreationViewControllerDidGoBack(_ viewController: ProfileCreationViewController) {
        navigationController.popViewController(animated: true)
    }
    
    func profileCreationViewControllerDidCompleteSignup(_ viewController: ProfileCreationViewController) {
        delegate?.authCoordinatorDidCompleteSignup(self)
    }
}
