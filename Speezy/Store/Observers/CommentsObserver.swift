//
//  CommentsObserver.swift
//  Speezy
//
//  Created by Matt Beaney on 24/07/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation

protocol CommentsObserver: AnyObject {
    func commentAdded(post: Post, comment: Comment)
    func initialCommentsReceived(post: Post, comments: [Comment])
    func commentRemoved(post: Post, comment: Comment)
    func pagedComments(post: Post, newComments: [Comment], allComments: [Comment])
}
