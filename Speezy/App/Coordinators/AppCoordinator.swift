//
//  AppCoordinator.swift
//  Speezy
//
//  Created by Matt Beaney on 20/07/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import Foundation
import UIKit

class AppCoordinator: ViewCoordinator {
    let tabBarController: UITabBarController
    
    init(tabBarController: UITabBarController) {
        self.tabBarController = tabBarController
    }
    
    override func start() {
        navigateToAuth()
    }
    
    override func finish() {
        
    }
    
    private func navigateToAuth() {
        let navigationController = UINavigationController()
        let coordinator = AuthCoordinator(navigationController: navigationController)
        coordinator.delegate = self
        add(coordinator)
        coordinator.start()
        
        tabBarController.setViewControllers([navigationController], animated: true)
    }
    
    private func navigateToHome() {
        tabBarController.tabBar.isHidden = false
        let homeCoordinator = HomeCoordinator(tabBarController: tabBarController)
        homeCoordinator.start()
    }
}

extension AppCoordinator: ChatCoordinatorDelegate {
    func chatCoordinatorDidFinish(_ coordinator: ChatCoordinator) {
        remove(coordinator)
    }
}

extension AppCoordinator: AuthCoordinatorDelegate {
    func authCoordinatorDidCompleteLogin(_ coordinator: AuthCoordinator) {
        navigateToHome()
    }
    
    func authCoordinatorDidCompleteSignup(_ coordinator: AuthCoordinator) {
        navigateToHome()
    }
    
    func authCoordinatorDidFinish(_ coordinator: AuthCoordinator) {
        remove(coordinator)
    }
}

extension AppCoordinator: AudioItemCoordinatorDelegate {    
    func audioItemCoordinatorDidSignOut(_ coordinator: AudioItemCoordinator) {
        remove(coordinator)
        navigateToAuth()
    }
    
    func audioItemCoordinatorDidFinish(_ coordinator: AudioItemCoordinator) {
        remove(coordinator)
    }
}

extension AppCoordinator: ContactsCoordinatorDelegate {
    func contactsCoordinatorDidFinish(_ coordinator: ContactsCoordinator) {
        remove(coordinator)
    }
}
