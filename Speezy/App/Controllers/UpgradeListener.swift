//
//  ListenForUpgrade.swift
//  Speezy
//
//  Created by Matt Beaney on 10/05/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation
import FirebaseFirestore

class UpgradeListener {
    enum Status: String {
        case requiresUpgrade
        case upgradeAdvised
        case noAction
    }
    
    func listenForUpgrade(completion: @escaping (Status) -> Void) {
        let db = Firestore.firestore()
        db.collection("upgrade").document("status").addSnapshotListener { (snapshot, error) in
            guard
                let result = snapshot?.data(),
                let supportedVersion = (result["supported_version"] as? String),
                let latestVersion = (result["latest_version"] as? String)
            else {
                completion(.noAction)
                return
            }
            
            guard
                let appVersionString = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
            else {
                completion(.noAction)
                return
            }
            
            if appVersionString.isSmallerThan(supportedVersion) {
                completion(.requiresUpgrade)
                return
            }
            
            if appVersionString.isSmallerThan(latestVersion) {
                completion(.upgradeAdvised)
                return
            }
            
            completion(.noAction)
        }
    }
}
