//
//  AppDelegate.swift
//  Speezy
//
//  Created by Matt Beaney on 27/05/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import UIKit
import Firebase
import FirebaseMessaging
import UserNotifications
import FBSDKCoreKit
import FirebaseFunctions
import FirebaseDatabase
import GoogleSignIn
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    let gcmMessageIDKey = "gcm.message_id"
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        configureFirebase()
        ApplicationDelegate.shared.application(
            application,
            didFinishLaunchingWithOptions: launchOptions
        )

        PushDeliveryHandler.shared.configurePush(app: application)
        UIApplication.shared.applicationIconBadgeNumber = 0
        ContactBackgroundFetchController.shared.registerBackgroundFetch()
        
        return true
    }
    
    private func configureFirebase() {
        guard
            let plistName = Bundle.main.infoDictionary?["GOOGLE_PLIST_NAME"] as? String,
            let filePath = Bundle.main.path(forResource: plistName, ofType: "plist"),
            let fileopts = FirebaseOptions(contentsOfFile: filePath)
        else {
            return
        }
        
        FirebaseApp.configure(options: fileopts)
        _ = Database.database().reference()
    }

    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey : Any] = [:]
    ) -> Bool {
        (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.handleDynamicLink(fromCustomScheme: url)
        
        ApplicationDelegate.shared.application(
            app,
            open: url,
            sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String,
            annotation: options[UIApplication.OpenURLOptionsKey.annotation]
        )

        return GIDSignIn.sharedInstance().handle(url)
    }
    
    func application(_ application: UIApplication, willContinueUserActivityWithType userActivityType: String) -> Bool {
        print(userActivityType)
        return true
    }
    
    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any]
    ) {
        // No-op right now, I'm not sure if we even need it.
    }

    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        // No-op right now, I'm not sure if we even need it.
    }
}
