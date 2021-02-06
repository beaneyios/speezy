//
//  DatabaseContactParser.swift
//  Speezy
//
//  Created by Matt Beaney on 23/01/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation

class ContactParser {
    static func parseContact(key: String, dict: NSDictionary) -> Contact? {
        guard
            let displayName = dict["display_name"] as? String,
            let userName = dict["user_name"] as? String
        else {
            return nil
        }
        
        return Contact(
            userId: key,
            displayName: displayName,
            userName: userName,
            profilePhotoUrl: URL(key: "profile_photo_url", dict: dict)
        )
    }
}
