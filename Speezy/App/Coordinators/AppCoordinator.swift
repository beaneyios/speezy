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
import FBSDKLoginKit

class AppCoordinator: ViewCoordinator {
    let tabBarController: UITabBarController
    var awaitingChatId: String?
    var awaitingContactId: String?
    var shouldDeepLinkToProfile: Bool = false
    var awaitingActivity: NSUserActivity?
    
    let signOutManager = SignOutManager.shared
    let store = Store.shared
    let tokenService = PushTokenSyncService()
    let killSwitchListener = KillSwitchListener()
    let upgradeListener = UpgradeListener()
    
    var killSwitchViewController: KillSwitchViewController? {
        tabBarController.presentedViewController as? KillSwitchViewController
    }
    
    init(tabBarController: UITabBarController) {
        self.tabBarController = tabBarController
    }
    
    override func start() {
        signOutManager.configure(
            auth: Auth.auth(),
            loginManager: LoginManager(),
            pushSyncService: tokenService,
            store: store
        )
        
        navigateToAuth()
        
        killSwitchListener.listenForKill { status in
            DispatchQueue.main.async {
                self.handleKillSwitchChange(status: status)
            }
        }
        
        upgradeListener.listenForUpgrade { (status) in
            DispatchQueue.main.async {
                self.handleUpgradeChange(status: status)
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
    
    func navigateToProfile() {
        guard let homeCoordinator = find(HomeCoordinator.self) else {
            return
        }
        
        homeCoordinator.navigateToProfile()
    }
    
    private func handleKillSwitchChange(status: Status?) {
        if let status = status {
            dismissAllViewControllers()
            
            signOutManager.signOut()
            
            navigateToAuth(animated: false)
            navigateToKillSwitch(status: status)
        } else if let killSwitchViewController = killSwitchViewController {
            killSwitchViewController.dismiss(
                animated: true,
                completion: nil
            )
        }
    }
    
    private func handleUpgradeChange(status: UpgradeListener.Status) {
        switch status {
        case .requiresUpgrade:
            showUpgradeAlert(
                title: "App update required",
                message: "This version of the app is no longer supported, tap below to update.",
                allowCancel: false
            )
        case .upgradeAdvised:
            showUpgradeAlert(
                title: "New update available",
                message: "There is a new version of Speezy available, tap below to update.",
                allowCancel: true
            )
        case .noAction:
            break
        }
    }
    
    private func showUpgradeAlert(
        title: String,
        message: String,
        allowCancel: Bool
    ) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let upgradeAction = UIAlertAction(title: "Upgrade", style: .default) { (action) in
            let storeUrl = URL(string: "https://apps.apple.com/gb/app/speezy/id1557121831")!
            UIApplication.shared.open(storeUrl, options: [:], completionHandler: nil)
            
            if allowCancel == false {
                self.showUpgradeAlert(
                    title: title,
                    message: message,
                    allowCancel: allowCancel
                )
            }
        }
        
        alert.addAction(upgradeAction)
        
        if allowCancel {
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            alert.addAction(cancelAction)
        }
        
        tabBarController.present(alert, animated: true, completion: nil)
    }
    
    private func navigateToKillSwitch(status: Status) {
        let storyboard = UIStoryboard(name: "Home", bundle: nil)
        let viewController = storyboard.instantiateViewController(identifier: "KillSwitchViewController") as! KillSwitchViewController
        viewController.status = status
        viewController.modalPresentationStyle = .fullScreen
        tabBarController.tabBar.isHidden = true
        tabBarController.present(viewController, animated: true, completion: nil)
    }
    
    private func navigateToAuth(animated: Bool = true, showDeletedAccount: Bool = false) {
        let navigationController = UINavigationController()
        let coordinator = AuthCoordinator(navigationController: navigationController)
        coordinator.delegate = self
        add(coordinator)
        coordinator.start()
        tabBarController.tabBar.isHidden = true
        tabBarController.setViewControllers([navigationController], animated: animated)
        
        if showDeletedAccount {
            let accountDeleted = UIAlertController(
                title: "Account deleted",
                message: "You have deleted your account, you will now be logged out",
                preferredStyle: .alert
            )
            
            let ok = UIAlertAction(title: "OK", style: .default, handler: nil)
            accountDeleted.addAction(ok)
            tabBarController.present(accountDeleted, animated: true, completion: nil)
        }
    }
    
    private func navigateToHome() {
        tabBarController.tabBar.isHidden = false
        let homeCoordinator = HomeCoordinator(tabBarController: tabBarController)
        homeCoordinator.delegate = self
        add(homeCoordinator)
        homeCoordinator.start(
            awaitingChatId: awaitingChatId,
            awaitingContactId: awaitingContactId,
            awaitingUserActivity: awaitingActivity,
            shouldDeepLinkToProfile: shouldDeepLinkToProfile
        )
        tabBarController.tabBar.isHidden = false
        
        awaitingContactId = nil
        awaitingChatId = nil
        awaitingActivity = nil
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
    func homeCoordinatorDidDeleteAccount(_ coordinator: HomeCoordinator) {
        navigateToAuth(showDeletedAccount: true)
        remove(coordinator)
    }
    
    func homeCoordinatorDidFinish(_ coordinator: HomeCoordinator) {
        remove(coordinator)
    }
    
    func homeCoordinatorDidLogOut(_ coordinator: HomeCoordinator) {
        navigateToAuth()
        remove(coordinator)
    }
}
