//
//  Poster.swift
//  Speezy
//
//  Created by Matt Beaney on 11/07/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation

struct Poster: Equatable, Hashable {
    var id: String
    var displayName: String
    var profileImageUrl: URL?
}

extension Poster {
    var toDict: [String: Any] {
        var dict = [
            "id": id,
            "display_name": displayName
        ]
        
        if let profileImageUrl = profileImageUrl {
            dict["profile_image_url"] = profileImageUrl.absoluteString
        }
        
        return dict
    }
    
    static func fromDict(dict: NSDictionary) -> Poster? {
        guard
            let id = dict["id"] as? String,
            let displayName = dict["display_name"] as? String
        else {
            return nil
        }
        
        return Poster(
            id: id,
            displayName: displayName,
            profileImageUrl: URL(key: "profile_image_url", dict: dict)
        )
    }
}
