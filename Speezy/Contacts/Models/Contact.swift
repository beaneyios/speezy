//
//  Contact.swift
//  Speezy
//
//  Created by Matt Beaney on 23/01/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation

struct Contact: Equatable, Identifiable {
    var id: String {
        userId
    }
    
    let userId: String
    let displayName: String
    let userName: String
    let profilePhotoUrl: URL?
}

extension Contact {
    var toDict: [String: Any] {
        var dict: [String: Any] = [
            "display_name": displayName,
            "user_name": userName
        ]
        
        if let profilePhotoUrl = profilePhotoUrl {
            dict["profile_photo_url"] = profilePhotoUrl.absoluteString
        }
        
        return dict
    }
    
    func withDisplayName(_ displayName: String) -> Self {
        Contact(
            userId: userId,
            displayName: displayName,
            userName: userName,
            profilePhotoUrl: profilePhotoUrl
        )
    }
    
    func withUserName(_ userName: String) -> Self {
        Contact(
            userId: userId,
            displayName: displayName,
            userName: userName,
            profilePhotoUrl: profilePhotoUrl
        )
    }
    
    func withProfilePhotoUrl(_ profilePhotoUrl: URL?) -> Self {
        Contact(
            userId: userId,
            displayName: displayName,
            userName: userName,
            profilePhotoUrl: profilePhotoUrl
        )
    }
}
