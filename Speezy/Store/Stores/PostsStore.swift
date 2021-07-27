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
    
    private(set) var posts = [Post]()
    private var observations = [ObjectIdentifier : PostsObservation]()
    private let serialQueue = DispatchQueue(label: "com.speezy.posts")
    
    func clear() {
        self.posts = []
        self.observations = [:]
    }
    
    func fetchNextPage(userId: String) {
        postsFetcher.fetchPosts(
            queryCount: 2,
            mostRecentPost: posts.last)
        { result in
            self.serialQueue.async {
                switch result {
                case let .success(newPosts):
                    self.handleNewPage(userId: userId, posts: newPosts)
                case .failure:
                    break
                }
            }
        }
    }
    
    private func handleNewPage(userId: String, posts: [Post]) {
        self.posts.insert(contentsOf: posts, at: 0)
        notifyObservers(
            change: .pagedPosts(newPosts: posts, allPosts: self.posts)
        )
    }
}

extension PostsStore {
    enum Change {
        case pagedPosts(newPosts: [Post], allPosts: [Post])
    }
    
    func addRecordingItemListObserver(_ observer: PostsObserver) {
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
                observer.pagedComments(newPosts: newPosts, allPosts: allPosts)
            }
        }
    }
}
