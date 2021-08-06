//
//  PostListener.swift
//  Speezy
//
//  Created by Matt Beaney on 06/08/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation
import FirebaseDatabase

class PostsListener {
    let post: Post
    var queries: [String: DatabaseQuery] = [:]
    
    init(post: Post) {
        self.post = post
    }
    
    func stopListening() {
        queries.values.forEach {
            $0.removeAllObservers()
        }
        
        queries = [:]
    }
    
    private func stopListeningForPostChanges(chatId: String) {
        queries.keys.filter {
            $0.contains(chatId)
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

// MARK: Post changes listening
extension PostsListener {
    func listenForChanges(completion: @escaping (PostValueChange) -> Void) {
        let postIdQueryKey = "\(post.id)_changes"
        removeQueryListener(forId: postIdQueryKey)
        
        let ref = Database.database().reference()
        let postChild: DatabaseReference = ref.child("posts/\(post.id)")
        let query = postChild.queryOrderedByKey()
        query.observe(.childChanged) { (snapshot) in
            guard
                let value = snapshot.value,
                let postValue = PostValue(key: snapshot.key, value: value)
            else {
                return
            }
            
            let change = PostValueChange(
                postId: self.post.id,
                postValue: postValue
            )
            completion(change)
        }
        
        queries[postIdQueryKey] = query
    }
}
