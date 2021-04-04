//
//  ChatterValue.swift
//  Speezy
//
//  Created by Matt Beaney on 21/02/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation

struct ChatterValueChange {
    let chatterId: String
    let chatterValue: ChatterValue
}

enum ChatterValue {
    case displayName(String)
    case lastRead(TimeInterval)
    case profileImageUrl(String)
    case pushToken(String)
    
    init?(key: String, value: Any) {
        switch (key, value) {
        case ("display_name", let value as String):
            self = .displayName(value)
        case ("last_read", let value as TimeInterval):
            self = .lastRead(value)
        case ("profile_image_url", let value as String):
            self = .profileImageUrl(value)
        case ("push_token", let value as String):
            self = .pushToken(value)
        default:
            return nil
        }
    }
}
