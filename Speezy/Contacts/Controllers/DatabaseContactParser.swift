//
//  DatabaseContactParser.swift
//  Speezy
//
//  Created by Matt Beaney on 23/01/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation

class DatabaseContactParser {
    static func parseContact(key: String, dict: NSDictionary) -> Contact? {
        guard let displayName = dict["display_name"] as? String else {
            return nil
        }
        
        return Contact(
            userId: key,
            displayName: displayName,
            profilePhotoUrl: URL(key: "profile_photo_url", dict: dict)
        )
    }
}
