//
//  SocialFeedViewModdel.swift
//  Speezy
//
//  Created by Matt Beaney on 27/07/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation

class SocialFeedViewModel {
    enum Change {
        case initialLoad
        case updated
    }
    
    var didChange: ((Change) -> Void)?
    
    private(set) var posts: [Post] = [Post]()
    private let store: Store
    
    var startPost: Post? {
        posts.first
    }
    
    init(store: Store = Store.shared) {
        self.store = store
        store.postsStore.addPostsObserver(self)
    }
    
    func loadData() {
        store.postsStore.fetchNextPage()
    }
    
    func post(after post: Post) -> Post? {
        guard
            let index = posts.firstIndex(of: post),
            (index + 1) < posts.count
        else {
            return nil
        }
        
        return posts[index + 1]
    }
    
    func post(before post: Post) -> Post? {
        guard
            let index = posts.firstIndex(of: post),
            (index - 1) > 0
        else {
            return nil
        }
        
        return posts[index - 1]
    }
}

extension SocialFeedViewModel: PostsObserver {
    func initialPostsReceived(posts: [Post]) {
        self.posts = posts
        didChange?(.initialLoad)
    }
    
    func pagedPosts(newPosts: [Post], allPosts: [Post]) {
        var oldPosts = self.posts
        self.posts = allPosts
        
        if oldPosts.count == 0 {
            didChange?(.updated)
        }
    }
}
