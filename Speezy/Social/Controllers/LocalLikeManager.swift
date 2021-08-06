//
//  LocalLikeManager.swift
//  Speezy
//
//  Created by Matt Beaney on 04/08/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation

struct Like: Codable {
    var id: String
}

class LocalLikeManager {
    static let shared = LocalLikeManager()
    
    private var likes: [Like] = []
    
    init() {
        likes = fetchLikes()
    }
    
    func postLiked(post: Post) -> Bool {
        likes.contains {
            $0.id == post.id
        }
    }
    
    func likePost(post: Post) {
        let like = Like(id: post.id)
        likes.append(like)
        Storage.store(likes, to: .documents, as: "likes")
    }
    
    func unlikePost(post: Post) {
        let like = Like(id: post.id)
        likes = likes.filter {
            $0.id != like.id
        }
        Storage.store(likes, to: .documents, as: "likes")
    }
    
    func fetchLikes() -> [Like] {
        Storage.retrieve("likes", from: .documents, as: [Like].self) ?? []
    }
}
