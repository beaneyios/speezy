//
//  SceneDelegate.swift
//  Speezy
//
//  Created by Matt Beaney on 27/05/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import UIKit
import FBSDKCoreKit
import Firebase
import FirebaseDynamicLinks

class SceneDelegate: UIResponder, UIWindowSceneDelegate, UIGestureRecognizerDelegate {

    var window: UIWindow?
    var appCoordinator: AppCoordinator!

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(frame: windowScene.coordinateSpace.bounds)
        window?.windowScene = windowScene
        
        let tabBarController = UITabBarController()
        let appCoordinator = AppCoordinator(tabBarController: tabBarController)
        
        PushDeliveryHandler.shared.configure(appCoordinator: appCoordinator)
        appCoordinator.awaitingChatId = PushDeliveryHandler.shared.chatId(from: connectionOptions)
        appCoordinator.awaitingActivity = connectionOptions.userActivities.first
        appCoordinator.start()
        
        self.appCoordinator = appCoordinator
        window?.rootViewController = tabBarController
        window?.makeKeyAndVisible()
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
        UIApplication.shared.applicationIconBadgeNumber = 0
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else {
            return
        }
        
        ApplicationDelegate.shared.application(
            UIApplication.shared,
            open: url,
            sourceApplication: nil,
            annotation: [UIApplication.OpenURLOptionsKey.annotation]
        )
    }
    
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        handleUserActivity(userActivity)
    }
    
    func handleUserActivity(_ userActivity: NSUserActivity) {
        guard let webPageUrl = userActivity.webpageURL else {
            return
        }
        
        DynamicLinks.dynamicLinks().handleUniversalLink(webPageUrl) { (dynamicLink, error) in
            guard let contactId = webPageUrl.queryParameters?["contact_id"] else {
                return
            }
            
            self.appCoordinator.navigateToAddContact(contactId: contactId)
        }
    }
    
    static var main: SceneDelegate? {
        UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate
    }
}

extension URL {
    var queryParameters: [String: String]? {
        guard
            let components = URLComponents(url: self, resolvingAgainstBaseURL: true),
            let queryItems = components.queryItems else { return nil }
        return queryItems.reduce(into: [String: String]()) { (result, item) in
            result[item.name] = item.value
        }
    }
}
