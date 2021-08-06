//
//  PostsStore.swift
//  Speezy
//
//  Created by Matt Beaney on 27/07/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation

class PostsStore {
    private let postsFetcher = PostsFetcher()
    private var postsListeners = [PostsListener]()
    
    private(set) var posts = [Post]()
    private var observations = [ObjectIdentifier : PostsObservation]()
    private let serialQueue = DispatchQueue(label: "com.speezy.posts")
    
    func clear() {
        self.posts = []
        self.observations = [:]
    }
    
    func fetchNextPage() {
        postsFetcher.fetchPosts(
            queryCount: 5,
            mostRecentPost: posts.last)
        { result in
            self.serialQueue.async {
                switch result {
                case let .success(newPosts):
                    self.handleNewPage(posts: newPosts)
                    
                    newPosts.forEach {
                        let post = $0
                        self.listenForPostChanges(post: post)
                    }
                case .failure:
                    break
                }
            }
        }
    }
    
    func listenForPostChanges(post: Post) {
        self.listener(post: post).listenForChanges { change in
            self.handlePostChanged(post: post, value: change)
        }
    }
    
    private func handlePostChanged(post: Post, value: PostValueChange) {
        var newPost = post
        
        switch value.postValue {
        case let .numberOfLikes(number):
            newPost.numberOfLikes = number
        case let .numberOfComments(number):
            newPost.numberOfComments = number
        }
        
        self.posts = self.posts.map {
            if $0.id == newPost.id {
                return newPost
            } else {
                return $0
            }
        }
        
        notifyObservers(
            change: .postChanged(post: newPost)
        )
    }
    
    private func listener(post: Post) -> PostsListener {
        postsListeners.first { $0.post.id == post.id } ?? PostsListener(post: post)
    }
    
    private func handleNewPage(posts: [Post]) {
        self.posts.insert(contentsOf: posts, at: 0)
        notifyObservers(
            change: .pagedPosts(newPosts: posts, allPosts: self.posts)
        )
    }
}

extension PostsStore {
    enum Change {
        case pagedPosts(newPosts: [Post], allPosts: [Post])
        case postChanged(post: Post)
    }
    
    func addPostsObserver(_ observer: PostsObserver) {
        serialQueue.async {
            let id = ObjectIdentifier(observer)
            self.observations[id] = PostsObservation(observer: observer)
            
            // We might be mid-load, let's give the new subscriber what we have so far.
            observer.initialPostsReceived(posts: self.posts)
        }
    }
    
    func removeRecordingItemListObserver(_ observer: PostsObserver) {
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
            case let .pagedPosts(newPosts, allPosts):
                observer.pagedPosts(newPosts: newPosts, allPosts: allPosts)
            case let .postChanged(post):
                observer.postChanged(newPost: post)
            }
        }
    }
}
