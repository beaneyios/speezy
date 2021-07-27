//
//  Post.swift
//  Speezy
//
//  Created by Matt Beaney on 11/07/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation

struct Post: Hashable {
    var id: String
    var poster: Poster
    var item: AudioItem
    var date: Date
}

extension Post {
    var toDict: [String: Any] {
        [
            "poster": poster.toDict,
            "item": item.toDict,
            "date": date.timeIntervalSince1970
        ]
    }
    
    static func fromDict(
        dict: NSDictionary,
        key: String
    ) -> Post? {
        guard
            let posterDict = dict["poster"] as? NSDictionary,
            let poster = Poster.fromDict(dict: posterDict),
            let itemDict = dict["item"] as? NSDictionary,
            let itemId = itemDict["id"] as? String,
            let item = AudioItem.fromDict(key: itemId, dict: itemDict),
            let dateInt = dict["date"] as? TimeInterval
        else {
            return nil
        }
        
        return Post(
            id: key,
            poster: poster,
            item: item,
            date: Date(timeIntervalSince1970: dateInt)
        )
    }
}
