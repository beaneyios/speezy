//
//  SceneDelegate.swift
//  Speezy
//
//  Created by Matt Beaney on 27/05/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate, UIGestureRecognizerDelegate {

    var window: UIWindow?
    var appCoordinator: AppCoordinator!

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        window = UIWindow(frame: windowScene.coordinateSpace.bounds)
        window?.windowScene = windowScene
        
        let navigationController = UINavigationController()
        self.appCoordinator = AppCoordinator(navigationController: navigationController)
        self.appCoordinator.start()
        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()
        
        //widget handling in scene (Stephen Karl)
        print("option 1")
        maybeOpenedFromWidget(urlContexts: connectionOptions.urlContexts, message: "Cold launch")
    }
    
    
    // App opened from background
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        print("option 2")
        maybeOpenedFromWidget(urlContexts: URLContexts, message: "Warm launch")
    }
    
    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not neccessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }
    
    //Widget handling (Stephen Karl)
    private func maybeOpenedFromWidget(urlContexts: Set<UIOpenURLContext>, message: String) {
        //print("widget handling")
        //print("\(urlContexts.first)")
        guard let _: UIOpenURLContext = urlContexts.first(where: { $0.url.scheme == "widget-SpeezyWidget" }) else { return }
        appCoordinator.showSuccess(message: message)
        print("🚀 Launched from widget")
    }

}
