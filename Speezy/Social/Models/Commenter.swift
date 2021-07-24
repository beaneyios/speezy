//
//  Commenter.swift
//  Speezy
//
//  Created by Matt Beaney on 23/07/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import UIKit

struct Commenter {
    let id: String
    let displayName: String
    let profileImageUrl: URL?
    let color: UIColor?
}

extension Commenter {
    var toDict: [String: Any] {
        [
            "id": id,
            "display_name": displayName,
            "profile_image_url": profileImageUrl?.absoluteString,
            "color": color?.asHex
        ]
    }
    
    static func fromDict(dict: NSDictionary) -> Commenter? {
        guard
            let id = dict["id"] as? String,
            let displayName = dict["display_name"] as? String
        else {
            return nil
        }
                
        return Commenter(
            id: id,
            displayName: displayName,
            profileImageUrl: URL(key: "profile_image_url", dict: dict),
            color: UIColor.fromDict(key: "color", dict: dict)
        )
    }
}
