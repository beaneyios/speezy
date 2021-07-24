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
    
    static func fromDict(
        dict: NSDictionary,
        key: String
    ) -> Comment? {
        guard
            let comment = dict["comment"] as? String,
            let commenterDict = dict["commenter"] as? NSDictionary,
            let commenter = Commenter.fromDict(dict: commenterDict),
            let dateSeconds = dict["date"] as? TimeInterval
        else {
            return nil
        }
        
        return Comment(
            id: key,
            commenter: commenter,
            comment: comment,
            date: Date(timeIntervalSince1970: dateSeconds)
        )
    }
}
