//
//  PushDeliveryHandler.swift
//  Speezy
//
//  Created by Matt Beaney on 04/02/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import UIKit
import UserNotifications
import FirebaseMessaging

class PushDeliveryHandler: NSObject {
    
    var awaitingChatId: String?
    var appCoordinator: AppCoordinator?
    
    let tokenSyncService = PushTokenSyncService()
    
    static let shared = PushDeliveryHandler()
    
    func configure(appCoordinator: AppCoordinator) {
        self.appCoordinator = appCoordinator
    }
    
    func handlePushFromWarmLaunch(request: UNNotificationRequest) {
        if request.identifier == ContactBackgroundFetchController.notificationId {
            appCoordinator?.navigateToProfile()
            return
        }
        
        let userInfo = request.content.userInfo
        
        guard
            let chatId = chatId(from: userInfo),
            let message = message(from: userInfo)
        else {
            return
        }
        
        appCoordinator?.navigateToChatId(chatId, message: message)
    }
    
    func chatId(from connectionOptions: UIScene.ConnectionOptions) -> String? {
        if
            let notification = connectionOptions.notificationResponse?.notification,
            let chatId = chatId(from: notification.request.content.userInfo)
        {
            return chatId
        }
        
        return nil
    }
    
    func shouldDeepLinkToProfile(from connectionOptions: UIScene.ConnectionOptions) -> Bool {
        guard let notification = connectionOptions.notificationResponse?.notification else {
            return false
        }
        
        return notification.request.identifier == ContactBackgroundFetchController.notificationId
    }
    
    func configurePush(app: UIApplication) {
        UNUserNotificationCenter.current().delegate = self
        
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(
            options: authOptions,
            completionHandler: {_, _ in }
        )
        
        app.registerForRemoteNotifications()
        Messaging.messaging().delegate = self
    }
    
    private func chatId(from userInfo: [AnyHashable: Any]) -> String? {
        userInfo["chatId"] as? String
    }
    
    private func message(from userInfo: [AnyHashable: Any]) -> String? {
        let aps = userInfo["aps"] as? [AnyHashable: Any]
        let alert = aps?["alert"] as? [AnyHashable: Any]
        
        guard
            let title = alert?["title"] as? String,
            let body = alert?["body"] as? String
        else {
            return nil
        }
        
        return "\(body) in \(title)"
    }
}

extension PushDeliveryHandler: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        _ = notification.request.content.userInfo
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        handlePushFromWarmLaunch(request: response.notification.request)
    }
}

extension PushDeliveryHandler: MessagingDelegate {
    func messaging(
        _ messaging: Messaging,
        didReceiveRegistrationToken fcmToken: String?
    ) {
        guard let fcmToken = fcmToken else {
            return
        }
        
        DispatchQueue.main.async {
            self.tokenSyncService.syncPushToken(token: fcmToken)
        }
    }
}
