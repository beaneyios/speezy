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
    
    let store = Store.shared
    let tokenService = PushTokenSyncService()
    
    init(tabBarController: UITabBarController) {
        self.tabBarController = tabBarController
    }
    
    override func start() {
        navigateToAuth()
    }
    
    override func finish() {
        
    }
    
    func navigateToChatId(_ chatId: String, message: String) {
        guard let homeCoordinator = find(HomeCoordinator.self) else {
            return
        }
        
        homeCoordinator.navigateToChatId(chatId, message: message)
    }
    
    private func navigateToAuth() {
        let navigationController = UINavigationController()
        let coordinator = AuthCoordinator(navigationController: navigationController)
        coordinator.delegate = self
        add(coordinator)
        coordinator.start()
        tabBarController.tabBar.isHidden = true
        tabBarController.setViewControllers([navigationController], animated: true)
    }
    
    private func navigateToHome() {
        tabBarController.tabBar.isHidden = false
        let homeCoordinator = HomeCoordinator(tabBarController: tabBarController)
        homeCoordinator.delegate = self
        add(homeCoordinator)
        homeCoordinator.start(withAwaitingChatId: awaitingChatId)
        tabBarController.tabBar.isHidden = false
        
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
    }
    
    func authCoordinatorDidCompleteSignup(
        _ coordinator: AuthCoordinator,
        withUser user: User
    ) {
        listenAndSync(user: user)
        navigateToHome()
    }
    
    func authCoordinatorDidFinish(_ coordinator: AuthCoordinator) {
        remove(coordinator)
    }
    
    private func listenAndSync(user: User) {
        tokenService.syncPushToken(userId: user.uid)
        store.startListeningForCoreChanges(userId: user.uid)
    }
}

extension AppCoordinator: HomeCoordinatorDelegate {
    func homeCoordinatorDidFinish(_ coordinator: HomeCoordinator) {
        remove(coordinator)
    }
    
    func homeCoordinatorDidLogOut(_ coordinator: HomeCoordinator) {
        navigateToAuth()
    }
}
