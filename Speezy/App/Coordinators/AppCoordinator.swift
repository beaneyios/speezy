//
//  AppCoordinator.swift
//  Speezy
//
//  Created by Matt Beaney on 20/07/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import Foundation
import UIKit
import FirebaseAuth

class AppCoordinator: ViewCoordinator {
    let tabBarController: UITabBarController
    var awaitingChatId: String?
    var awaitingContactId: String?
    
    let store = Store.shared
    let tokenService = PushTokenSyncService()
    let killSwitchListener = KillSwitchListener()
    
    var killSwitchViewController: KillSwitchViewController? {
        tabBarController.presentedViewController as? KillSwitchViewController
    }
    
    init(tabBarController: UITabBarController) {
        self.tabBarController = tabBarController
    }
    
    override func start() {
        navigateToAuth()
        
        killSwitchListener.listenForKill { status in
            DispatchQueue.main.async {
                self.handleKillSwitchChange(status: status)
            }
        }
    }
    
    override func finish() {}
    
    func navigateToAddContact(contactId: String) {
        guard let homeCoordinator = find(HomeCoordinator.self) else {
            awaitingContactId = contactId
            return
        }
        
        homeCoordinator.navigateToAddContact(contactId: contactId)
    }
    
    func navigateToChatId(_ chatId: String, message: String) {
        guard let homeCoordinator = find(HomeCoordinator.self) else {
            return
        }
        
        homeCoordinator.navigateToChatId(chatId, message: message)
    }
    
    private func handleKillSwitchChange(status: Status?) {
        if let status = status {
            dismissAllViewControllers()
            try? Auth.auth().signOut()
            store.userDidLogOut()
            navigateToAuth(animated: false)
            navigateToKillSwitch(status: status)
        } else if let killSwitchViewController = killSwitchViewController {
            killSwitchViewController.dismiss(
                animated: true,
                completion: nil
            )
        }
    }
    
    private func navigateToKillSwitch(status: Status) {
        let storyboard = UIStoryboard(name: "Home", bundle: nil)
        let viewController = storyboard.instantiateViewController(identifier: "KillSwitchViewController") as! KillSwitchViewController
        viewController.status = status
        viewController.modalPresentationStyle = .fullScreen
        tabBarController.tabBar.isHidden = true
        tabBarController.present(viewController, animated: true, completion: nil)
    }
    
    private func navigateToAuth(animated: Bool = true) {
        let navigationController = UINavigationController()
        let coordinator = AuthCoordinator(navigationController: navigationController)
        coordinator.delegate = self
        add(coordinator)
        coordinator.start()
        tabBarController.tabBar.isHidden = true
        tabBarController.setViewControllers([navigationController], animated: animated)
    }
    
    private func navigateToHome() {
        tabBarController.tabBar.isHidden = false
        let homeCoordinator = HomeCoordinator(tabBarController: tabBarController)
        homeCoordinator.delegate = self
        add(homeCoordinator)
        homeCoordinator.start(
            withAwaitingChatId: awaitingChatId,
            andAwaitingContactId: awaitingContactId
        )
        tabBarController.tabBar.isHidden = false
        
        awaitingContactId = nil
        awaitingChatId = nil
    }
}

extension AppCoordinator: AuthCoordinatorDelegate {
    func authCoordinatorDidCompleteLogin(
        _ coordinator: AuthCoordinator,
        withUser user: User
    ) {
        listenAndSync(user: user)
        navigateToHome()
        remove(coordinator)
    }
    
    func authCoordinatorDidCompleteSignup(
        _ coordinator: AuthCoordinator,
        withUser user: User
    ) {
        listenAndSync(user: user)
        navigateToHome()
        remove(coordinator)
    }
    
    func authCoordinatorDidFinish(_ coordinator: AuthCoordinator) {
        remove(coordinator)
    }
    
    private func listenAndSync(user: User) {
        tokenService.syncPushToken(userId: user.uid)
        store.startListeningForCoreChanges(userId: user.uid)
    }
    
    private func dismissAllViewControllers() {
        tabBarController.viewControllers?.forEach {
            $0.dismiss(animated: true, completion: nil)
        }
    }
}

extension AppCoordinator: HomeCoordinatorDelegate {
    func homeCoordinatorDidFinish(_ coordinator: HomeCoordinator) {
        remove(coordinator)
    }
    
    func homeCoordinatorDidLogOut(_ coordinator: HomeCoordinator) {
        navigateToAuth()
        remove(coordinator)
    }
}
