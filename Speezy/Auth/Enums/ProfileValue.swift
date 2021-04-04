//
//  UserValue.swift
//  Speezy
//
//  Created by Matt Beaney on 13/02/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation

struct ProfileValueChange {
    let userId: String
    let profileValue: ProfileValue
}

enum ProfileValue {
    case name(String)
    case userName(String)
    case occupation(String)
    case aboutYou(String)
    case profileImageUrl(URL?)
    case pushToken(String?)
    
    init?(key: String, value: Any) {
        if key == "name", let name = value as? String {
            self = .name(name)
        } else if key == "username", let username = value as? String {
            self = .userName(username)
        } else if key == "occupation", let occupation = value as? String {
            self = .occupation(occupation)
        } else if key == "profile_image" {
            self = .profileImageUrl(URL(string: value as? String))
        } else if key == "about", let aboutYou = value as? String {
            self = .aboutYou(aboutYou)
        } else if key == "push_token", let pushToken = value as? String {
            self = .pushToken(pushToken)
        } else {
            return nil
        }
    }
}
