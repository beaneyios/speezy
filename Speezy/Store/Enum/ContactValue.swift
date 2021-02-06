//
//  ContactValue.swift
//  Speezy
//
//  Created by Matt Beaney on 06/02/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation

struct ContactValueChange {
    let contactId: String
    let contactValue: ContactValue
}

enum ContactValue {
    case displayName(String)
    case profilePhotoUrl(String)
    case userName(String)
    
    init?(key: String, value: Any) {
        if key == "display_name", let displayName = value as? String {
            self = .displayName(displayName)
        } else if key == "profile_photo_url", let profilePhotoUrl = value as? String {
            self = .profilePhotoUrl(profilePhotoUrl)
        } else if key == "user_name", let userName = value as? String {
            self = .userName(userName)
        } else {
            return nil
        }
    }
}
