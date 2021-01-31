//
//  Chatter.swift
//  Speezy
//
//  Created by Matt Beaney on 18/01/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import UIKit

struct Chatter: Equatable {
    let id: String
    let displayName: String
    let profileImageUrl: URL?
    let pushToken: String?
}

extension Array where Element == Chatter {
    func chatter(for id: String) -> Chatter? {
        first { $0.id == id }
    }
}

extension Chatter {
    var toDict: [String: Any] {
        var dict: [String: Any] = [
            "display_name": displayName
        ]
        
        if let profileImageUrl = profileImageUrl {
            dict["profile_image_url"] = profileImageUrl.absoluteString
        }
        
        if let pushToken = pushToken {
            dict["push_token"] = pushToken
        }
        
        return dict
    }    
}
