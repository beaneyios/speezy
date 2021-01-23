//
//  EmailSignup.swift
//  Speezy
//
//  Created by Matt Beaney on 30/12/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import Foundation

struct Profile {
    var name: String = ""
    var userName: String = ""
    var occupation: String = ""
    var aboutYou: String = ""
    var profileImageUrl: URL?
    
    init() {}
    
    init?(dict: NSDictionary) {
        guard
            let name = dict["name"] as? String,
            let username = dict["username"] as? String,
            let occupation = dict["occupation"] as? String,
            let about = dict["about"] as? String
        else {
            return nil
        }
        
        self.name = name
        self.userName = username
        self.occupation = occupation
        self.aboutYou = about
        self.profileImageUrl = nil
    }
}
