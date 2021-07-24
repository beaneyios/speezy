//
//  CommentFetcher.swift
//  Speezy
//
//  Created by Matt Beaney on 24/07/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation
import FirebaseDatabase

class CommentsFetcher {
    func fetchComments(
        post: Post,
        queryCount: UInt,
        mostRecentComment: Comment? = nil,
        completion: @escaping (Result<[Comment], Error>) -> Void
    ) {
        let ref = Database.database().reference()
        let chatChild: DatabaseReference = ref.child("comments/\(post.id)")
        
        let query: DatabaseQuery = {
            if let comment = mostRecentComment {
                return chatChild
                    .queryOrderedByKey()
                    .queryEnding(atValue: comment.id)
                    .queryLimited(toLast: 5)
            } else {
                return chatChild.queryOrderedByKey().queryLimited(toLast: queryCount)
            }
        }()
        
        query.observeSingleEvent(of: .value) { (snapshot) in
            guard let result = snapshot.value as? NSDictionary else {
                completion(.success([]))
                return
            }
            
            let comments: [Comment] = result.allKeys.compactMap {
                guard
                    let key = $0 as? String,
                    let dict = result[key] as? NSDictionary
                else {
                    return nil
                }
                
                return Comment.fromDict(
                    dict: dict,
                    key: key
                )
            }.sorted {
                $0.date > $1.date
            }.filter {
                $0.id != mostRecentComment?.id
            }
            
            completion(.success(comments))
        } withCancel: { (error) in
            completion(.failure(error))
        }
    }
}
