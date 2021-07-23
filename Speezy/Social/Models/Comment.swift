//
//  Comment.swift
//  Speezy
//
//  Created by Matt Beaney on 23/07/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation

struct Comment {
    let id: String
    let commenter: Commenter
    let comment: String
    let date: Date
}

extension Comment {
    var toDict: [String: Any] {
        [
            "commenter": commenter.toDict,
            "comment": comment,
            "date": date.timeIntervalSince1970
        ]
    }
}
