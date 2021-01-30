//
//  HomeCoordinator.swift
//  Speezy
//
//  Created by Matt Beaney on 30/01/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import UIKit

class HomeCoordinator: ViewCoordinator {
    enum TabBarTab: Int {
        case audio
        case chat
        case profile
        case contacts
    }
    
    private let tabBarController: UITabBarController
    
    init(tabBarController: UITabBarController) {
        self.tabBarController = tabBarController
    }
    
    override func start() {
        tabBarController.setViewControllers([], animated: false)
        addAudioCoordinator()
        addChatCoordinator()
        addQuickRecord()
        addContactsCoordinator()
        addProfileCoordinator()
    }
    
    private func addAudioCoordinator() {
        let navigationController = UINavigationController()
        navigationController.setNavigationBarHidden(true, animated: false)
        let coordinator = AudioItemCoordinator(navigationController: navigationController)
        coordinator.delegate = self
        add(coordinator)
        coordinator.start()
        addTab(withIconName: "home-tab-item", containing: navigationController)
    }
    
    private func addQuickRecord() {
        let navigationController = UINavigationController()
        navigationController.setNavigationBarHidden(true, animated: false)
        let coordinator = ContactsCoordinator(navigationController: navigationController)
        coordinator.delegate = self
        add(coordinator)
        coordinator.start()
        
        let imageInsets = UIDevice.current.userInterfaceIdiom == .pad
                    ? UIEdgeInsets(top: -10, left: 0, bottom: 10, right: 0)
                    : UIEdgeInsets(top: -10, left: 0, bottom: -10, right: 0)
        
        navigationController.tabBarItem.image = UIImage(
            named: "speezy-tab-item"
        )?.withRenderingMode(.alwaysOriginal)
        navigationController.tabBarItem.imageInsets = imageInsets

        
        tabBarController.viewControllers?.append(navigationController)
    }
    
    private func addContactsCoordinator() {
        let navigationController = UINavigationController()
        navigationController.setNavigationBarHidden(true, animated: false)
        let coordinator = ContactsCoordinator(navigationController: navigationController)
        coordinator.delegate = self
        add(coordinator)
        coordinator.start()
        addTab(withIconName: "contact-tab-item", containing: navigationController)
    }
    
    private func addChatCoordinator() {
        let navigationController = UINavigationController()
        navigationController.setNavigationBarHidden(true, animated: false)
        let coordinator = ChatCoordinator(navigationController: navigationController)
        coordinator.delegate = self
        add(coordinator)
        coordinator.start()
        addTab(withIconName: "chat-tab-item", containing: navigationController)
    }
    
    private func addProfileCoordinator() {
        let navigationController = UINavigationController()
        navigationController.setNavigationBarHidden(true, animated: false)
        let coordinator = ChatCoordinator(navigationController: navigationController)
        coordinator.delegate = self
        add(coordinator)
        coordinator.start()
        addTab(withIconName: "profile-tab-item", containing: navigationController)
    }
    
    private func addTab(
        withIconName iconName: String,
        containing viewController: UIViewController
    ) {
        viewController.tabBarItem.image = UIImage(named: iconName)
        tabBarController.tabBar.tintColor = .speezyPurple
        tabBarController.tabBar.unselectedItemTintColor = .black
        tabBarController.viewControllers?.append(viewController)
    }
}

extension HomeCoordinator: AudioItemCoordinatorDelegate {
    func audioItemCoordinatorDidFinish(_ coordinator: AudioItemCoordinator) {
        remove(coordinator)
    }
    
    func audioItemCoordinatorDidSignOut(_ coordinator: AudioItemCoordinator) {
        
    }
}

extension HomeCoordinator: ChatCoordinatorDelegate {
    func chatCoordinatorDidFinish(_ coordinator: ChatCoordinator) {
        remove(coordinator)
    }
}

extension HomeCoordinator: ContactsCoordinatorDelegate {
    func contactsCoordinatorDidFinish(_ coordinator: ContactsCoordinator) {
        remove(coordinator)
    }
}
