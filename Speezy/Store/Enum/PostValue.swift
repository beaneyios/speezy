//
//  PostValueChange.swift
//  Speezy
//
//  Created by Matt Beaney on 06/08/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation

struct PostValueChange {
    let postId: String
    let postValue: PostValue
}

enum PostValue {
    case numberOfLikes(Int)
    case numberOfComments(Int)
    
    init?(key: String, value: Any) {
        switch (key, value) {
        case ("number_of_likes", let value as Int):
            self = .numberOfLikes(value)
        case ("number_of_comments", let value as Int):
            self = .numberOfComments(value)
        default:
            return nil
        }
    }
    
    var key: String {
        switch self {
        case .numberOfLikes:
            return "number_of_likes"
        case .numberOfComments:
            return "number_of_comments"
        }
    }
    
    var value: Any {
        switch self {
        case let .numberOfLikes(numberOfLikes):
            return numberOfLikes
        case let .numberOfComments(numberOfComments):
            return numberOfComments
        }
    }
}
