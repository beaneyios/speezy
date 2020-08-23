//
//  SettingsCoordinator.swift
//  Speezy
//
//  Created by Matt Beaney on 02/08/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import Foundation
import UIKit

protocol SettingsCoordinatorDelegate: AnyObject {
    func settingsCoordinatorDidFinish(_ coordinator: SettingsCoordinator)
}

class SettingsCoordinator: ViewCoordinator {
    let storyboard = UIStoryboard(name: "Settings", bundle: nil)
    let navigationController: UINavigationController
    
    weak var delegate: SettingsCoordinatorDelegate?
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    override func start() {
        let listViewController = storyboard.instantiateViewController(identifier: "SettingsItemListViewController") as! SettingsItemListViewController
        listViewController.title = "Settings"
        listViewController.delegate = self
        navigationController.pushViewController(listViewController, animated: true)
    }
    
    override func finish() {
        delegate?.settingsCoordinatorDidFinish(self)
    }
}

extension SettingsCoordinator: SettingsItemListViewControllerDelegate {
    func settingsItemListViewController(_ viewController: SettingsItemListViewController, didSelectSettingsItem item: SettingsItem) {
        switch item.identifier {
        case .acknowledgements:
            navigateToAcknowledgements()
        case .privacyPolicy:
            navigateToPrivacyPolicy()
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
