//
//  PlaybackViewModel.swift
//  Speezy
//
//  Created by Matt Beaney on 11/07/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import UIKit

class PlaybackViewModel {
    enum Change {
        case imageLoaded(UIImage)
    }
    
    var didChange: ((Change) -> Void)?
    
    let post: Post
    
    let attachmentManager: AudioAttachmentManager = AudioAttachmentManager()
    let profileImageFetcher: ProfileImageFetcher = ProfileImageFetcher()
    let manager: AudioManager
    
    init(post: Post) {
        self.post = post
        self.manager = AudioManager(item: post.item)
    }
    
    func loadData() {        
        if post.item.attachmentUrl != nil {
            fetchAttachment()
        } else {
            fetchProfileImage()
        }
    }
    
    private func fetchAudio() {
        CloudAudioManager.downloadAudioClip(id: post.item.id) { result in
            switch result {
            case let .success(item):
                break
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
                break
            }
        }
    }
    
    private func fetchProfileImage() {
        profileImageFetcher.fetchImage(id: post.poster.id) { result in
            switch result {
            case let .success(image):
                self.didChange?(.imageLoaded(image))
            case let .failure(error):
                break
            }
        }
    }
    
}

extension PlaybackViewModel {
    
}
