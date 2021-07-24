//
//  CommentStore.swift
//  Speezy
//
//  Created by Matt Beaney on 24/07/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation

class CommentsStore {
    private let commentsFetcher = CommentsFetcher()
    private var commentsListeners = [CommentsListener]()
    
    private(set) var comments = [Post: [Comment]]()
    private var noMoreComments = [Post: Bool]()
    
    private var observations = [ObjectIdentifier : CommentsObservation]()
    private let serialQueue = DispatchQueue(label: "com.speezy.comments")
    
    private var loading = false
    
    func clear() {
        self.comments = [:]
        self.observations = [:]
    }
    
    func fetchNextPage(
        post: Post,
        queryCount: UInt
    ) {
        guard
            shouldLoadComments(post: post)
        else {
            return
        }
        
        loading = true
        
        commentsFetcher.fetchComments(
            post: post,
            queryCount: queryCount
        ) { result in
            self.serialQueue.async {
                switch result {
                case let .success(newComments):
                    if newComments.count == 1 && self.commentExists(id: newComments[0].id) {
                        self.noMoreComments[post] = true
                    }
                    
                    let oldComments = self.comments[post]
                    self.handleNewPage(post: post, newComments: newComments)
                    
                    // This is the first load and we've now processed the the first page.
                    // So now we can start listening for additions, knowing that the first addition
                    // will be a duplicate, but will get processed.
                    if oldComments == nil {
                        self.listenForNewComments(
                            mostRecentComment: newComments.first,
                            post: post
                        )
                        
                        self.listenForDeletedComments(post: post)
                    }
                    
                    self.loading = false
                case .failure:
                    break
                }
            }
        }
    }
    
    func listenForNewComments(
        mostRecentComment: Comment?,
        post: Post
    ) {
        let listener: CommentsListener = self.listener(post: post)
        listener.listenForCommentAdditions(mostRecentComment: mostRecentComment) { result in
            self.serialQueue.async {
                switch result {
                case let .success(newComment):
                    self.handleCommentAdded(comment: newComment, post: post)
                case let .failure(error):
                    break
                }
            }
        }
        
        commentsListeners = commentsListeners.replacing(listener)
    }
    
    func listenForDeletedComments(post: Post) {
        let listener: CommentsListener = self.listener(post: post)
        listener.listenForCommentDeletions { result in
            switch result {
            case let .success(commentId):
                self.serialQueue.async {
                    self.handleCommentRemoved(commentId: commentId)
                    guard self.comments[post]?.index(commentId) == 0 else {
                        return
                    }
                    
                    self.listenForNewComments(
                        mostRecentComment: self.mostRecentComment(post: post),
                        post: post
                    )
                }
            case let.failure(error):
                break
            }
        }
    }
    
    private func handleNewPage(post: Post, newComments: [Comment]) {
        let comments = self.comments[post] ?? []
        let mergedComments = comments.appending(elements: newComments)
        self.comments[post] = mergedComments

        notifyObservers(
            change: .pagedComments(
                post: post,
                newComments: newComments,
                allComments: mergedComments
            )
        )
    }
    
    private func handleCommentAdded(comment: Comment, post: Post) {
        guard
            let comments = comments[post],
            !allComments.contains(comment)
        else {
            return
        }

        self.comments[post] = comments.inserting(comment)
        notifyObservers(
            change: .commentAdded(post: post, comment: comment)
        )
    }
    
    private func handleCommentRemoved(commentId: String) {
        guard
            let post = self.post(forCommentId: commentId),
            let comment = comment(for: commentId),
            let comments = self.comments[post]
        else {
            return
        }
        
        self.comments[post] = comments.removing(commentId)
        
        notifyObservers(
            change: .commentRemoved(post: post, comment: comment)
        )
    }
    
    var allComments: [Comment] {
        comments.flatMap {
            $0.value
        }
    }
    
    private func post(forCommentId id: String) -> Post? {
        comments.first {
            $0.value.contains(elementWithId: id)
        }.map {
            $0.key
        }
    }
    
    private func comment(for id: String) -> Comment? {
        allComments.first {
            $0.id == id
        }
    }
    
    private func commentExists(id: String) -> Bool {
        comment(for: id) != nil
    }
    
    private func listener(post: Post) -> CommentsListener {
        commentsListeners.first { $0.post.id == post.id } ?? CommentsListener(post: post)
    }
    
    private func mostRecentComment(post: Post) -> Comment? {
        comments[post]?.first
    }
    
    private func shouldLoadComments(post: Post) -> Bool {
        (noMoreComments[post] == nil || noMoreComments[post] == false) && !loading
    }
}

extension CommentsStore {
    enum Change {
        case commentAdded(post: Post, comment: Comment)
        case commentRemoved(post: Post, comment: Comment)
        case pagedComments(post: Post, newComments: [Comment], allComments: [Comment])
        case initialComments(post: Post, comments: [Comment])
    }
    
    func addCommentsObserver(_ observer: CommentsObserver, post: Post) {
        serialQueue.async {
            let id = ObjectIdentifier(observer)
            self.observations[id] = CommentsObservation(observer: observer)
            
            // We might be mid-load, let's give the new subscriber what we have so far.
            observer.initialCommentsReceived(post: post, comments: self.comments[post] ?? [])
        }
    }
    
    func removeCommentsObserver(_ observer: CommentsObserver) {
        serialQueue.async {
            let id = ObjectIdentifier(observer)
            self.observations.removeValue(forKey: id)
        }
    }
    
    private func notifyObservers(change: Change) {
        observations.forEach {
            guard let observer = $0.value.observer else {
                observations.removeValue(forKey: $0.key)
                return
            }
            
            switch change {
            case let .commentAdded(post, comment):
                observer.commentAdded(post: post, comment: comment)
            case let .commentRemoved(post, comment):
                observer.commentRemoved(post: post, comment: comment)
            case let .pagedComments(post, newComments, allComments):
                observer.pagedComments(post: post, newComments: newComments, allComments: allComments)
            case let .initialComments(post, comments):
                observer.initialCommentsReceived(post: post, comments: comments)
            }
        }
    }
}
