//
//  SettingsCoordinator.swift
//  Speezy
//
//  Created by Matt Beaney on 02/08/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import Foundation
import UIKit
import FirebaseAuth
import FBSDKLoginKit
import GoogleSignIn

protocol SettingsCoordinatorDelegate: AnyObject {
    func settingsCoordinatorDidDeleteAccount(_ coordinator: SettingsCoordinator)
    func settingsCoordinatorDidLogOut(_ coordinator: SettingsCoordinator)
    func settingsCoordinatorDidFinish(_ coordinator: SettingsCoordinator)
}

class SettingsCoordinator: ViewCoordinator, NavigationControlling {
    let storyboard = UIStoryboard(name: "Settings", bundle: nil)
    let navigationController: UINavigationController
    
    weak var delegate: SettingsCoordinatorDelegate?
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    override func start() {
        let listViewController = storyboard.instantiateViewController(identifier: "SettingsItemListViewController") as! SettingsViewController
        listViewController.title = "Settings"
        listViewController.delegate = self
        navigationController.pushViewController(listViewController, animated: true)
    }
    
    override func finish() {
        delegate?.settingsCoordinatorDidFinish(self)
    }
    
    deinit {
        print("Weee")
    }
}

extension SettingsCoordinator: SettingsItemListViewControllerDelegate {
    func settingsItemListViewController(_ viewController: SettingsViewController, didSelectSettingsItem item: SettingsItem) {
        switch item {
        case .acknowledgements:
            navigateToAcknowledgements()
        case .privacyPolicy:
            navigateToPrivacyPolicy()
        case .logout:
            Store.shared.userDidLogOut()
            try? Auth.auth().signOut()
            LoginManager().logOut()
            delegate?.settingsCoordinatorDidLogOut(self)
            delegate?.settingsCoordinatorDidFinish(self)
        case .deleteAccount:
            Store.shared.userDidLogOut()
            try? Auth.auth().signOut()
            LoginManager().logOut()
            delegate?.settingsCoordinatorDidDeleteAccount(self)
            delegate?.settingsCoordinatorDidFinish(self)
        default:
            break
        }
    }
    
    private func navigateToAcknowledgements() {
        let privacyViewController = storyboard.instantiateViewController(identifier: "PrivacyPolicyViewController") as! WebViewViewController
        privacyViewController.titleText = "Acknowledgements"
        privacyViewController.path = "acknowledgements"
        navigationController.pushViewController(privacyViewController, animated: true)
    }
    
    private func navigateToPrivacyPolicy() {
        let privacyViewController = storyboard.instantiateViewController(identifier: "PrivacyPolicyViewController") as! WebViewViewController
        privacyViewController.titleText = "Privacy Policy"
        privacyViewController.path = "privacy-policy"
        navigationController.pushViewController(privacyViewController, animated: true)
    }
}
