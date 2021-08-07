//
//  CommentsViewModel.swift
//  Speezy
//
//  Created by Matt Beaney on 24/07/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation

class CommentsViewModel {
    enum Change {
        case updated
        case loading(Bool)
        case postUpdated
    }
    
    private var typedComment = ""
    private let commentCreator = CommentCreator()
    private let postLiker = PostLiker()
    
    private(set) var post: Post
    let store: Store
    var profile: Profile?
    
    var didChange: ((Change) -> Void)?
    
    private(set) var comments: [Comment] = []
    
    var liked: Bool {
        LocalLikeManager.shared.postLiked(post: post)
    }
    
    init(post: Post, store: Store = Store.shared) {
        self.post = post
        self.store = store
        
        store.profileStore.addProfileObserver(self)
        store.commentsStore.addCommentsObserver(self, post: post)
        store.postsStore.addPostsObserver(self)
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
    
    func like() {
        if LocalLikeManager.shared.postLiked(post: post) {
            postLiker.unlike(post: post)
            LocalLikeManager.shared.unlikePost(post: post)
        } else {
            postLiker.like(post: post)
            LocalLikeManager.shared.likePost(post: post)
        }
    }
    
    private func fetchComments() {
        let queryCount: UInt = 7
        self.didChange?(.loading(true))
        self.store.commentsStore.fetchNextPage(post: self.post, queryCount: queryCount)
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

extension CommentsViewModel: PostsObserver {
    func initialPostsReceived(posts: [Post]) {}
    func pagedPosts(newPosts: [Post], allPosts: [Post]) {}
    func postAdded(newPost: Post) {}
    
    func postChanged(newPost: Post) {
        if newPost.id != post.id {
            return
        }
        
        self.post = newPost
        didChange?(.postUpdated)
    }
}

extension CommentsViewModel: CommentsObserver {
    func commentAdded(
        post: Post,
        comment: Comment
    ) {
        guard post.id == self.post.id else {
            return
        }
        
        self.comments.insert(comment, at: 0)
        didChange?(.updated)
    }
    
    func initialCommentsReceived(
        post: Post,
        comments: [Comment]
    ) {
        guard post.id == self.post.id else {
            return
        }
        
        if comments.isEmpty {
            fetchComments()
        } else {
            self.comments = comments
            didChange?(.updated)
        }
    }
    
    func commentRemoved(
        post: Post,
        comment: Comment
    ) {
        guard post.id == self.post.id else {
            return
        }
        
        self.comments = comments.removing(comment.id)
        didChange?(.updated)
    }
    
    func pagedComments(
        post: Post,
        newComments: [Comment],
        allComments: [Comment]
    ) {
        guard post.id == self.post.id else {
            return
        }
        
        self.comments = allComments
        didChange?(.updated)
    }
}
