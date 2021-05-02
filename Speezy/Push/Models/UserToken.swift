//
//  UserToken.swift
//  Speezy
//
//  Created by Matt Beaney on 28/01/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation

struct UserToken {
    let userId: String
    let token: String
    
    init(userId: String, token: String) {
        self.userId = userId
        self.token = token
    }
    
    init(key: String, value: String) {
        self.userId = key
        self.token = value
    }
}

extension Array where Element == UserToken {
    init(dict: [String: String]?) {
        guard let dict = dict else {
            self = []
            return
        }
        
        self = dict.map({ (keyValuePair) -> UserToken in
            UserToken(key: keyValuePair.key, value: keyValuePair.value)
        })
    }
}
