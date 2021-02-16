//
//  ProfileListener.swift
//  Speezy
//
//  Created by Matt Beaney on 13/02/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation
import FirebaseDatabase

class ProfileListener {
    enum Change {
        case profileUpdated(ProfileValueChange)
    }

    var didChange: ((Change) -> Void)?
    var handle: DatabaseHandle?
    let ref = Database.database().reference()
    
    func listenForProfileChanges(userId: String) {
        let profileChild: DatabaseReference = ref.child("user/\(userId)/profile")
        handle = profileChild.observe(.childChanged) { (snapshot) in
            guard
                let value = snapshot.value,
                let profileValue = ProfileValue(key: snapshot.key, value: value)
            else {
                return
            }
            
            let change = ProfileValueChange(
                userId: userId,
                profileValue: profileValue
            )
            self.didChange?(.profileUpdated(change))
        }        
    }
    
    func stopListening() {
        guard let handle = self.handle else {
            return
        }
        
        ref.removeObserver(withHandle: handle)
    }
}

