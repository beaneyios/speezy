//
//  CommentCreator.swift
//  Speezy
//
//  Created by Matt Beaney on 23/07/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation
import FirebaseDatabase

class CommentCreator {
    func createComment(
        post: Post,
        comment: String,
        user: Profile,
        completion: @escaping (Result<Comment, Error>) -> Void
    ) {
        let ref = Database.database().reference()
        
        let child = ref.child("comments/\(post.id)").childByAutoId()
        
        guard let key = child.key else {
            return
        }
        
        let comment = Comment(
            id: key,
            commenter: Commenter(
                id: user.userId,
                displayName: user.userName,
                profileImageUrl: user.profileImageUrl,
                color: UIColor.random
            ),
            comment: comment,
            date: Date()
        )
        
        child.updateChildValues(comment.toDict)
    }
}
