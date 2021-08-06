//
//  PostCreator.swift
//  Speezy
//
//  Created by Matt Beaney on 27/07/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation
import FirebaseDatabase

class PostCreator {
    func createPost(
        item: AudioItem,
        user: Profile,
        completion: @escaping (Result<Post, Error>) -> Void
    ) {
        let ref = Database.database().reference()
        let child = ref.child("posts").childByAutoId()
        
        guard let key = child.key else {
            return
        }
        
        let poster = Poster(
            id: user.userId,
            displayName: user.userName,
            profileImageUrl: user.profileImageUrl
        )
        
        let post = Post(
            id: key,
            poster: poster,
            item: item,
            date: Date(),
            numberOfLikes: 0,
            numberOfComments: 0
        )
        
        child.updateChildValues(post.toDict) { error, ref in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(post))
            }
        }
    }
}
