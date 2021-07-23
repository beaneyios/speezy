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
            "profile_image_url": profileImageUrl,
            "color": color
        ]
    }
}
