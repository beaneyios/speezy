//
//  CommentListener.swift
//  Speezy
//
//  Created by Matt Beaney on 24/07/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation
import FirebaseDatabase

class CommentsListener: Identifiable {
    typealias CommentFetchHandler = (Result<Comment, Error>) -> Void
        
    var queries: [String: DatabaseQuery] = [:]
    let post: Post
    
    var id: String {
        post.id
    }
    
    init(post: Post) {
        self.post = post
    }
    
    func listenForCommentAdditions(
        mostRecentComment: Comment?,
        completion: @escaping CommentFetchHandler
    ) {
        let userIdQueryKey = "\(post.id)_additions"
        removeQueryListener(forId: userIdQueryKey)
        
        let ref = Database.database().reference()
        let commentsChild = ref.child("comments/\(post.id)")
        let query = commentsChild.queryOrderedByKey().queryLimited(toLast: 1)
        
        query.observe(.childAdded) { (snapshot) in
            guard
                let dict = snapshot.value as? NSDictionary,
                let comment = Comment.fromDict(dict: dict, key: snapshot.key)
            else {
                return
            }
            
            completion(.success(comment))
        } withCancel: { (error) in
            print(error)
        }

        queries[userIdQueryKey] = query
    }
    
    func listenForCommentDeletions(completion: @escaping (Result<String, Error>) -> Void) {
        let userIdQueryKey = "\(post.id)_deletions"
        removeQueryListener(forId: userIdQueryKey)
        
        let ref = Database.database().reference()
        let commentsChild = ref.child("comments/\(post.id)")
        let query = commentsChild.queryOrderedByKey()
        query.observe(.childRemoved) { (snapshot) in
            completion(.success(snapshot.key))
            self.stopListeningForCommentChanges(commentId: snapshot.key)
        }
        
        queries[userIdQueryKey] = query
    }
    
    func stopListening() {
        queries.values.forEach {
            $0.removeAllObservers()
        }
        
        queries = [:]
    }
    
    private func stopListeningForCommentChanges(commentId: String) {
        queries.keys.filter {
            $0.contains(commentId)
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
