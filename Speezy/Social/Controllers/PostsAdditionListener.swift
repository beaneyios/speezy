//
//  PostsAdditionListener.swift
//  Speezy
//
//  Created by Matt Beaney on 06/08/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation
import FirebaseDatabase

class PostsAdditionListener {
    typealias PostFetchHandler = (Result<Post, Error>) -> Void
    var queries: [String: DatabaseQuery] = [:]
    
    func listenForPostAdditions(
        mostRecentPost: Post?,
        completion: @escaping PostFetchHandler
    ) {
        let userIdQueryKey = "additions"
        removeQueryListener(forId: userIdQueryKey)
        
        let ref = Database.database().reference()
        let postsChild = ref.child("posts")
        let query = postsChild.queryOrderedByKey().queryLimited(toLast: 1)
        
        query.observe(.childAdded) { (snapshot) in
            guard
                let dict = snapshot.value as? NSDictionary,
                let post = Post.fromDict(dict: dict, key: snapshot.key)
            else {
                return
            }
            
            completion(.success(post))
        } withCancel: { (error) in
            print(error)
        }

        queries[userIdQueryKey] = query
    }
    
    func stopListening() {
        queries.values.forEach {
            $0.removeAllObservers()
        }
        
        queries = [:]
    }
    
    private func stopListeningForPostChanges(postId: String) {
        queries.keys.filter {
            $0.contains(postId)
        }.compactMap {
            self.queries[$0]
        }.forEach {
            $0.removeAllObservers()
        }
    }
    
    private func removeQueryListener(forId id: String) {
        guard let currentQuery = queries[id] else {
            return
        }
        
        currentQuery.removeAllObservers()
    }
}
