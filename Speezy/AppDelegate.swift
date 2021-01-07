//
//  AppDelegate.swift
//  Speezy
//
//  Created by Matt Beaney on 27/05/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import UIKit
import Firebase

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        FirebaseApp.configure()
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
        
        //karl added - but too strong for full player
        //UIApplication.shared.isIdleTimerDisabled = false
    }

    //MARK: - Widget URL handling
    //private added to silence a warning
    //func application(_ application: UIApplication, openURL url: NSURL, options: [String : AnyObject]) -> Bool {
    func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        print("URL received")
        let message = url.host?.removingPercentEncoding // foobarmessage
        //return true
        
        if url.scheme == "widget-SpeezyWidget" {
            //let title = // get the title out of the URL's query using a method of your choice
            //let body = // get the title out of the URL's query using a method of your choice
            print ("Go with URL")
            //self.rootViewController.createTaskWithTitle(title, body: body)
            return true
        }

        return false
    }
    
    /*func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
       let message = url.host?.removingPercentEncoding // foobarmessage
       return true
    }
   */
    
}

