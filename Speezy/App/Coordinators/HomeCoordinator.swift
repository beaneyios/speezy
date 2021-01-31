//
//  HomeCoordinator.swift
//  Speezy
//
//  Created by Matt Beaney on 30/01/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import UIKit

protocol HomeCoordinatorDelegate: AnyObject {
    func homeCoordinatorDidFinish(_ coordinator: HomeCoordinator)
    func homeCoordinatorDidLogOut(_ coordinator: HomeCoordinator)
}

class HomeCoordinator: ViewCoordinator {
    enum TabBarTab: Int {
        case audio
        case chat
        case profile
        case contacts
    }
    
    weak var delegate: HomeCoordinatorDelegate?
    
    private let tabBarController: UITabBarController
    
    init(tabBarController: UITabBarController) {
        self.tabBarController = tabBarController
    }
    
    override func start() {
        tabBarController.setViewControllers([], animated: false)
        addChatCoordinator()
        addAudioCoordinator()
        addQuickRecord()
        addContactsCoordinator()
        addSettingsCoordinator()
        
        tabBarController.delegate = self
    }
    
    func navigateToChatId(_ chatId: String, message: String) {
        let presentedViewController = childCoordinators.compactMap {
            ($0 as? NavigationControlling)?.navigationController.presentedViewController
        }.first
        
        if let presentedViewController = presentedViewController {
            let alert = UIAlertController(
                title: message,
                message: "Once you're done, you'll find your message in the chats list",
                preferredStyle: .alert
            )
            
            let ok = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(ok)
            presentedViewController.present(alert, animated: true, completion: nil)
            return
        }
        
        tabBarController.selectedIndex = 0
        
        guard let chatCoordinator = find(ChatCoordinator.self) else {
            return
        }
        
        chatCoordinator.navigateToChatId(chatId, message: message)
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
    
    private class DummyRecordViewController: UIViewController {}
    private func addQuickRecord() {
        let dummyController = DummyRecordViewController()
        let imageInsets = UIEdgeInsets(top: -10, left: 0, bottom: 5, right: 0)
        
        dummyController.tabBarItem.image = UIImage(
            named: "speezy-tab-item"
        )?.withRenderingMode(.alwaysOriginal)
        dummyController.tabBarItem.imageInsets = imageInsets
        tabBarController.viewControllers?.append(dummyController)
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
    
    private func addSettingsCoordinator() {
        let navigationController = UINavigationController()
        navigationController.setNavigationBarHidden(true, animated: false)
        let settingsCoordinator = SettingsCoordinator(navigationController: navigationController)
        settingsCoordinator.delegate = self
        add(settingsCoordinator)
        settingsCoordinator.start()
        
        addTab(withIconName: "settings-tab-item", containing: navigationController)
    }
    
    private func addTab(
        withIconName iconName: String,
        containing viewController: UIViewController
    ) {
        viewController.tabBarItem.title = nil
        viewController.tabBarItem.image = UIImage(named: iconName)
        tabBarController.tabBar.tintColor = .speezyPurple
        tabBarController.tabBar.unselectedItemTintColor = .black
        tabBarController.viewControllers?.append(viewController)
    }
}

extension HomeCoordinator: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        if viewController is DummyRecordViewController {
            tabBarController.selectedIndex = 1
            guard
                let audioCoordinator = find(AudioItemCoordinator.self),
                let listViewController = audioCoordinator.listViewController
            else {
                return false
            }
            
            
            listViewController.presentQuickRecordDialogue(
                item: listViewController.viewModel.newItem,
                startHeight: 30.0
            )
            
            tabBarController.tabBar.isHidden = true
            return false
        }
        
        return true
    }
}

extension HomeCoordinator: AudioItemCoordinatorDelegate {
    func audioItemCoordinatorDidFinishRecording(_ coordinator: AudioItemCoordinator) {
        tabBarController.tabBar.isHidden = false
    }
    
    func audioItemCoordinatorDidFinish(_ coordinator: AudioItemCoordinator) {
        remove(coordinator)
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

extension HomeCoordinator: SettingsCoordinatorDelegate {
    func settingsCoordinatorDidLogOut(_ coordinator: SettingsCoordinator) {
        delegate?.homeCoordinatorDidLogOut(self)
    }
    
    func settingsCoordinatorDidFinish(_ coordinator: SettingsCoordinator) {
        remove(coordinator)
    }
}
