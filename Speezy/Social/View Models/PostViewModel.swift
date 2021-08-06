//
//  PostViewModel.swift
//  Speezy
//
//  Created by Matt Beaney on 11/07/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import UIKit

final class PostViewModel {
    enum Change {
        case imageLoaded(UIImage)
        case audioLoading
        case audioLoaded
        case postUpdated(Post)
    }
    
    var didChange: ((Change) -> Void)?
    
    private(set) var post: Post
    
    let attachmentManager: AudioAttachmentManager = AudioAttachmentManager()
    let profileImageFetcher: ProfileImageFetcher = ProfileImageFetcher()
    let manager: AudioManager
    
    init(post: Post, store: Store = Store.shared) {
        self.post = post
        self.manager = AudioManager(item: post.item)
        store.postsStore.addPostsObserver(self)
    }
    
    func loadData() {        
        if post.item.attachmentUrl != nil {
            fetchAttachment()
        } else {
            fetchProfileImage()
        }
        
        fetchAudio()
    }
    
    private func fetchAudio() {
        didChange?(.audioLoading)
        CloudAudioManager.downloadAudioClip(id: post.item.id) { result in
            switch result {
            case let .success(item):
                self.didChange?(.audioLoaded)
            case let .failure(error):
                break
            }
        }
    }
    
    private func fetchAttachment() {
        attachmentManager.fetchAttachment(forItem: post.item) { result in
            switch result {
            case let .success(image):
                self.didChange?(.imageLoaded(image))
            case let .failure(error):
                print(error?.localizedDescription)
            }
        }
    }
    
    private func fetchProfileImage() {
        profileImageFetcher.fetchImage(id: post.poster.id) { result in
            switch result {
            case let .success(image):
                self.didChange?(.imageLoaded(image))
            case let .failure(error):
                print(error?.localizedDescription)
            }
        }
    }
}

extension PostViewModel {
    var viewTitle: String {
        post.item.title
    }
}

extension PostViewModel: PostsObserver {
    func initialPostsReceived(posts: [Post]) {}
    func pagedPosts(newPosts: [Post], allPosts: [Post]) {}
    
    func postChanged(newPost: Post) {
        if newPost.id != self.post.id {
            return
        }
        
        self.post = newPost
        self.didChange?(.postUpdated(newPost))
    }
}
