//
//  PostLiker.swift
//  Speezy
//
//  Created by Matt Beaney on 04/08/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation
import FirebaseDatabase

class PostLiker {
    func like(post: Post) {
        let ref = Database.database().reference()
        let child = ref.child("posts/\(post.id)/number_of_likes")
        child.setValue(ServerValue.increment(1))
    }
    
    func unlike(post: Post) {
        let ref = Database.database().reference()
        let child = ref.child("posts/\(post.id)/number_of_likes")
        child.setValue(ServerValue.increment(-1))
    }
}
