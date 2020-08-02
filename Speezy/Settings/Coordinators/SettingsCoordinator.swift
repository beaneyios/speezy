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
        navigationController.pushViewController(listViewController, animated: true)
    }
    
    override func finish() {
        delegate?.settingsCoordinatorDidFinish(self)
    }
}

extension SettingsCoordinator: SettingsItemListViewControllerDelegate {
    func settingsItemListViewController(_ viewController: SettingsItemListViewController, didSelectSettingsItem item: SettingsItem) {
        
    }
}
