//
//  CommentsViewModel.swift
//  Speezy
//
//  Created by Matt Beaney on 24/07/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation

class CommentsViewModel {
    private var typedComment = ""
    private let commentCreator = CommentCreator()
    
    let post: Post
    var profile: Profile?
    
    private(set) var comments: [Comment] = []
    
    init(post: Post, store: Store = Store.shared) {
        self.post = post
        
        store.profileStore.addProfileObserver(self)
    }
    
    func submitComment() {
        guard let profile = profile else {
            return
        }
        
        if typedComment.count > 3 {
            commentCreator.createComment(
                post: post,
                comment: typedComment,
                user: profile)
            { result in
                switch result {
                case let .success(comment):
                    break
                case let .failure(error):
                    break
                }
            }
        } else {
            // TODO: Handle error.
        }
    }
    
    func updateTypedComment(_ comment: String) {
        self.typedComment = comment
    }
}

extension CommentsViewModel: ProfileObserver {
    func initialProfileReceived(profile: Profile) {
        self.profile = profile
    }
    
    func profileUpdated(profile: Profile) {
        self.profile = profile
    }
}
