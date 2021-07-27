//
//  PostFetcher.swift
//  Speezy
//
//  Created by Matt Beaney on 26/07/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation
import FirebaseDatabase

class PostsFetcher {
    func fetchPosts(
        queryCount: UInt,
        mostRecentPost: Post? = nil,
        completion: @escaping (Result<[Post], Error>) -> Void
    ) {
        let ref = Database.database().reference()
        let postChild: DatabaseReference = ref.child("posts")
        
        let query: DatabaseQuery = {
            if let post = mostRecentPost {
                return postChild
                    .queryOrderedByKey()
                    .queryEnding(atValue: post.id)
                    .queryLimited(toLast: 5)
            } else {
                return postChild.queryOrderedByKey().queryLimited(toLast: queryCount)
            }
        }()
        
        query.observeSingleEvent(of: .value) { (snapshot) in
            guard let result = snapshot.value as? NSDictionary else {
                completion(.success([]))
                return
            }
            
            let posts: [Post] = result.allKeys.compactMap {
                guard
                    let key = $0 as? String,
                    let dict = result[key] as? NSDictionary
                else {
                    return nil
                }
                
                return Post.fromDict(dict: dict, key: key)
            }.sorted {
                $0.date > $1.date
            }.filter {
                $0.id != mostRecentPost?.id
            }
            
            completion(.success(posts))
        } withCancel: { (error) in
            completion(.failure(error))
        }
    }
}
