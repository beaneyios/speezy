//
//  HomeCoordinator.swift
//  Speezy
//
//  Created by Matt Beaney on 30/01/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import UIKit
import FirebaseDynamicLinks
import JGProgressHUD

protocol HomeCoordinatorDelegate: AnyObject {
    func homeCoordinatorDidFinish(_ coordinator: HomeCoordinator)
    func homeCoordinatorDidLogOut(_ coordinator: HomeCoordinator)
    func homeCoordinatorDidDeleteAccount(_ coordinator: HomeCoordinator)
}

class HomeCoordinator: ViewCoordinator {
    enum TabBarTab: Int {
        case chat
        case audio
        case speezy
        case contacts
        case settings
    }
    
    weak var delegate: HomeCoordinatorDelegate?
    
    private let tabBarController: UITabBarController
    
    init(tabBarController: UITabBarController) {
        self.tabBarController = tabBarController
    }
    
    func start(
        awaitingChatId chatId: String?,
        awaitingContactId contactId: String?,
        awaitingUserActivity userActivity: NSUserActivity?,
        shouldDeepLinkToProfile: Bool
    ) {
        tabBarController.setViewControllers([], animated: false)
        addChatCoordinator(awaitingChatId: chatId)
        addAudioListCoordinator()
        addQuickRecord()
        addProfileCoordinator()
        addSettingsCoordinator()
        
        tabBarController.delegate = self
        
        handleAwaitingActivities(
            chatId: chatId,
            contactId: contactId,
            userActivity: userActivity,
            shouldDeepLinkToProfile: shouldDeepLinkToProfile
        )
    }
    
    func navigateToAddContact(contactId: String) {
        tabBarController.selectedIndex = TabBarTab.contacts.rawValue
        
        guard let profileCoordinator = find(ProfileCoordinator.self) else {
            return
        }
        
        profileCoordinator.navigateToAddContact(contactId: contactId)
    }
    
    func navigateToProfile() {
        tabBarController.selectedIndex = TabBarTab.contacts.rawValue
        
        guard let profileCoordinator = find(ProfileCoordinator.self) else {
            return
        }
        
        profileCoordinator.profileEditViewController?.highlightAddButton()
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
        
        tabBarController.selectedIndex = TabBarTab.chat.rawValue
        
        guard let chatCoordinator = find(ChatCoordinator.self) else {
            return
        }
        
        chatCoordinator.navigateToChatId(chatId, message: message)
    }
    
    private func handleAwaitingActivities(
        chatId: String?,
        contactId: String?,
        userActivity: NSUserActivity?,
        shouldDeepLinkToProfile: Bool
    ) {
        if chatId != nil {
            return
        }
        
        if shouldDeepLinkToProfile {
            navigateToProfile()
        } else if let contactId = contactId {
            navigateToAddContact(contactId: contactId)
        } else if let userActivity = userActivity {
            handleUserActivity(userActivity)
        }
    }
    
    private func handleUserActivity(_ userActivity: NSUserActivity) {
        guard let webPageUrl = userActivity.webpageURL else {
            return
        }
        
        let hud = JGProgressHUD()
        hud.textLabel.text = "Loading..."
        hud.show(in: self.tabBarController.view)
        
        guard let contactId = DeepLinkHandler.contactId(for: webPageUrl) else {
            hud.dismiss()
            return
        }
        
        hud.dismiss()
        self.navigateToAddContact(contactId: contactId)
    }
    
    private func addAudioListCoordinator() {
        let navigationController = UINavigationController()
        navigationController.setNavigationBarHidden(true, animated: false)
        let coordinator = AudioItemListCoordinator(navigationController: navigationController)
        coordinator.delegate = self
        add(coordinator)
        coordinator.start()
        addTab(withIconName: "home-tab-item", containing: navigationController)
    }
    
    private class DummyRecordViewController: UIViewController {}
    private func addQuickRecord() {
        let dummyController = DummyRecordViewController()
        let imageInsets = UIEdgeInsets(top: -5, left: 0, bottom: 1, right: 0)
        
        dummyController.tabBarItem.image = UIImage(
            named: "speezy-tab-item"
        )?.withRenderingMode(.alwaysOriginal)
        dummyController.tabBarItem.imageInsets = imageInsets
        tabBarController.viewControllers?.append(dummyController)
    }
    
    private func addProfileCoordinator() {
        let navigationController = UINavigationController()
        navigationController.setNavigationBarHidden(true, animated: false)
        let coordinator = ProfileCoordinator(navigationController: navigationController)
        coordinator.delegate = self
        add(coordinator)
        coordinator.start()
        addTab(withIconName: "contact-tab-item", containing: navigationController)
    }
    
    private func addChatCoordinator(awaitingChatId: String?) {
        let navigationController = UINavigationController()
        navigationController.setNavigationBarHidden(true, animated: false)
        let coordinator = ChatCoordinator(navigationController: navigationController)
        coordinator.delegate = self
        add(coordinator)
        coordinator.start(withAwaitingChatId: awaitingChatId)
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
        tabBarController.tabBar.unselectedItemTintColor = .label
        tabBarController.viewControllers?.append(viewController)
    }
}

extension HomeCoordinator: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        if viewController is DummyRecordViewController {
            tabBarController.selectedIndex = TabBarTab.audio.rawValue
            guard
                let audioCoordinator = find(AudioItemListCoordinator.self),
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

extension HomeCoordinator: AudioItemListCoordinatorDelegate {
    func audioItemCoordinator(_ coordinator: AudioItemListCoordinator, didShareItemToSpeezy item: AudioItem) {
        tabBarController.selectedIndex = TabBarTab.chat.rawValue
        
        guard let chatCoordinator = find(ChatCoordinator.self) else {
            return
        }
        
        chatCoordinator.shareItemToChat(audioItem: item)
    }
    
    func audioItemCoordinatorDidFinishRecording(_ coordinator: AudioItemListCoordinator) {
        tabBarController.tabBar.isHidden = false
    }
    
    func audioItemCoordinatorDidFinish(_ coordinator: AudioItemListCoordinator) {
        remove(coordinator)
    }
}

extension HomeCoordinator: ChatCoordinatorDelegate {
    func chatCoordinatorDidFinish(_ coordinator: ChatCoordinator) {
        remove(coordinator)
    }
}

extension HomeCoordinator: ProfileCoordinatorDelegate {
    func profileCoordinatorDidFinish(_ coordinator: ProfileCoordinator) {
        remove(coordinator)
    }
}

extension HomeCoordinator: SettingsCoordinatorDelegate {
    func settingsCoordinatorDidDeleteAccount(_ coordinator: SettingsCoordinator) {
        delegate?.homeCoordinatorDidDeleteAccount(self)
    }
    
    func settingsCoordinatorDidLogOut(_ coordinator: SettingsCoordinator) {
        delegate?.homeCoordinatorDidLogOut(self)
    }
    
    func settingsCoordinatorDidFinish(_ coordinator: SettingsCoordinator) {
        remove(coordinator)
    }
}
