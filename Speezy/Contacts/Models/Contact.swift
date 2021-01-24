//
//  Contact.swift
//  Speezy
//
//  Created by Matt Beaney on 23/01/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation

struct Contact: Equatable {
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
}
