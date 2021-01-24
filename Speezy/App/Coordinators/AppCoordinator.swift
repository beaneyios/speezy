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
    let navigationController: UINavigationController
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    override func start() {
        navigateToAuth()
    }
    
    override func finish() {
        
    }
    
    private func navigateToAudioItems() {
        let coordinator = AudioItemCoordinator(navigationController: navigationController)
        coordinator.delegate = self
        add(coordinator)
        coordinator.start()
    }
    
    private func navigateToAuth() {
        let coordinator = AuthCoordinator(navigationController: navigationController)
        coordinator.delegate = self
        add(coordinator)
        coordinator.start()
    }
    
    private func navigateToChat() {
        let coordinator = ChatCoordinator(navigationController: navigationController)
        coordinator.delegate = self
        add(coordinator)
        coordinator.start()
    }
    
    private func navigateToContacts() {
        let coordinator = ContactsCoordinator(navigationController: navigationController)
        coordinator.delegate = self
        add(coordinator)
        coordinator.start()
    }
    
    private func navigateToHome() {
        let homeStoryboard = UIStoryboard(name: "Home", bundle: nil)
        let homeViewController = homeStoryboard.instantiateViewController(identifier: "HomeViewController") as! HomeViewController
        homeViewController.delegate = self
        navigationController.setViewControllers([homeViewController], animated: true)
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

extension AppCoordinator: HomeViewControllerDelegate {
    func homeViewControllerDidSelectChats(_ viewController: HomeViewController) {
        navigateToChat()
    }
    
    func homeViewControllerDidSelectAudio(_ viewController: HomeViewController) {
        navigateToAudioItems()
    }
    
    func homeViewControllerDidSelectContacts(_ viewController: HomeViewController) {
        navigateToContacts()
    }
    
    func homeViewControllerDidSelectSignOut(_ viewController: HomeViewController) {
        navigateToAuth()
    }
}
