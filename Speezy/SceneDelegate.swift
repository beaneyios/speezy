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
        
        //widget handling in scene (Stephen Karl)
        maybeOpenedFromWidget(urlContexts: connectionOptions.urlContexts, message: "Cold launch")
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
        
        maybeOpenedFromWidget(urlContexts: URLContexts, message: "Warm launch")
        
        ApplicationDelegate.shared.application(
            UIApplication.shared,
            open: url,
            sourceApplication: nil,
            annotation: [UIApplication.OpenURLOptionsKey.annotation]
        )
    }
    
    //Widget handling (Stephen Karl)
    private func maybeOpenedFromWidget(urlContexts: Set<UIOpenURLContext>, message: String) {
        //print("widget handling")
        //print("\(urlContexts.first)")
        guard let _: UIOpenURLContext = urlContexts.first(where: { $0.url.scheme == "widget-SpeezyWidget" }) else { return }
        appCoordinator.showSuccess(message: message)
        print("🚀 Launched from widget")
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
