//
//  KillSwitchListener.swift
//  Speezy
//
//  Created by Matt Beaney on 14/03/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation
import FirebaseFirestore

struct Status {
    var title: String
    var message: String
}

class KillSwitchListener {
    func listenForKill(completion: @escaping (Status?) -> Void) {
        let db = Firestore.firestore()
        db.collection("kill-switch").document("status").addSnapshotListener { (snapshot, error) in
            guard
                let result = snapshot?.data(),
                let dead = result["dead"] as? Bool,
                dead == true,
                let title = result["title"] as? String,
                let message = result["message"] as? String
            else {
                completion(
                    nil
                )
                return
            }
            
            completion(
                Status(title: title, message: message)
            )
        }
    }
}
