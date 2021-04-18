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
    private let pushTime = 10.0
    
    private let stageKey = "contact_notification_key"
    private var stage: Stage {
        guard let defaultStage = UserDefaults.standard.object(forKey: stageKey) as? String else {
            return .firstTry
        }
        
        return Stage(rawValue: defaultStage) ?? .firstTry
    }
    
    enum Stage: String {
        case firstTry
        case secondTry
        case thirdTry
        case complete
        
        var earliestRefreshTimeInterval: TimeInterval? {
            let minute = 60.0
            let hour = minute * 60.0
            let day = hour * 24.0
            
            switch self {
            case .firstTry:
                return minute * 10.0
            case .secondTry:
                return minute * 20.0
            case .thirdTry:
                return minute * 30.0
            case .complete:
                return nil
            }
        }
    }
    
    func registerBackgroundFetch() {
        if stage == .complete {
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
        guard let earliestRefreshTimeInterval = stage.earliestRefreshTimeInterval else {
            return
        }
        
        let task = BGAppRefreshTaskRequest(identifier: taskKey)
        task.earliestBeginDate = Date().addingTimeInterval(earliestRefreshTimeInterval)
        
        do {
            try BGTaskScheduler.shared.submit(task)
        } catch {
            NSLog("Background task failed to submit for reason: \(error)")
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
                self.setStage(stage: .complete)
            } else {
                self.incrementStage()
                self.scheduleLocalNotification()
                self.scheduleContactFetch()
            }
            
            task.setTaskCompleted(success: true)
        }
    }
    
    private func incrementStage() {
        switch stage {
        case .firstTry:
            setStage(stage: .secondTry)
        case .secondTry:
            setStage(stage: .thirdTry)
        case .thirdTry, .complete:
            break
        }
    }
    
    private func setStage(stage: Stage) {
        UserDefaults.standard.setValue(stage.rawValue, forKey: stageKey)
    }
}
