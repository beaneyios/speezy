//
//  ContactBackgroundFetchController.swift
//  Speezy
//
//  Created by Matt Beaney on 05/04/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation
import BackgroundTasks
import FirebaseDatabase
import FirebaseAuth

class ContactBackgroundFetchController {
    static var shared = ContactBackgroundFetchController()
    
    static let notificationId = "ContactNotification"
    
    private let taskKey = "com.suggestv.speezy.contacts"
    private let defaultKey = "contact_notification_check"
    private let refreshTime = 60.0 * 60.0 * 24.0
    private let pushTime = 10.0
    
    func registerBackgroundFetch() {
        if contactLimitHit {
            return
        }
        
        BGTaskScheduler.shared.register(forTaskWithIdentifier: taskKey, using: nil) { (task) in
            guard let refreshTask = task as? BGAppRefreshTask else {
                task.setTaskCompleted(success: false)
                return
            }
            
            self.fetchContacts(task: refreshTask)
        }
    }
    
    func scheduleContactFetch() {
        let task = BGAppRefreshTaskRequest(identifier: taskKey)
        task.earliestBeginDate = Date().addingTimeInterval(refreshTime)
        
        do {
            try BGTaskScheduler.shared.submit(task)
        } catch {
            assertionFailure("Unable to submit task: \(error.localizedDescription)")
        }
    }
    
    func cancelAllRequests() {
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: taskKey)
    }
    
    func scheduleLocalNotification() {
        let content = UNMutableNotificationContent()
        content.title = "You don't have many friends"
        content.body = "Get the most from Speezy by sharing your account with a few more of your friends."
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: pushTime, repeats: false)
        let request = UNNotificationRequest(
            identifier: Self.notificationId,
            content: content,
            trigger: trigger
        )
        
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.add(request) { _ in }
    }
    
    private func fetchContacts(task: BGAppRefreshTask) {
        guard let userId = Auth.auth().currentUser?.uid else {
            return
        }
        
        let ref = Database.database().reference()
        let userContacts = ref.child("users/\(userId)/contacts")
        
        userContacts.observeSingleEvent(of: .value) { (snapshot) in
            guard let value = snapshot.value as? NSDictionary else {
                return
            }
            
            if value.allKeys.count > 7 {
                self.setContactLimitHit()
            } else {
                self.scheduleLocalNotification()
                self.scheduleContactFetch()
            }
            
            task.setTaskCompleted(success: true)
        }
    }
    
    var contactLimitHit: Bool {
        UserDefaults.standard.bool(forKey: defaultKey)
    }
    
    private func setContactLimitHit() {
        UserDefaults.standard.set(true, forKey: defaultKey)
    }
}
