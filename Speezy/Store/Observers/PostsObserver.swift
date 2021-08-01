//
//  PostsObserver.swift
//  Speezy
//
//  Created by Matt Beaney on 27/07/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation

protocol PostsObserver: AnyObject {
    func initialPostsReceived(posts: [Post])
    func pagedPosts(newPosts: [Post], allPosts: [Post])
}
