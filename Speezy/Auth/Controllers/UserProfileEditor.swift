//
//  UserProfileEditor.swift
//  Speezy
//
//  Created by Matt Beaney on 30/12/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import Foundation
import FirebaseFirestore

class FirebaseUserProfileEditor {
    func updateUserProfile(
        userId: String,
        profile: Profile,
        completion: @escaping () -> Void
    ) {
        let db = Firestore.firestore()
        
        db.collection("users").document(userId).setData([
            "name": profile.name,
            "about": profile.aboutYou
        ]) { (error) in
            completion()
        }
    }
}
