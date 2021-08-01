//
//  PublishViewModel.swift
//  Speezy
//
//  Created by Matt Beaney on 01/08/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation

class PublishViewModel {
    enum Change {
        case postCreated(Post)
    }
    
    var didChange: ((Change) -> Void)?
    
    private var profile: Profile?
    private let store: Store
    
    let postCreator = PostCreator()
    
    init(store: Store = Store.shared) {
        self.store = store
        store.profileStore.addProfileObserver(self)
    }
    
    func createPost(item: AudioItem) {
        guard let profile = profile else {
            return
        }
        
        postCreator.createPost(
            item: item,
            user: profile
        ) { result in
            switch result {
            case let .success(post):
                self.didChange?(.postCreated(post))
            case let .failure(error):
                break
            }
        }
    }
}

extension PublishViewModel: ProfileObserver {
    func initialProfileReceived(profile: Profile) {
        self.profile = profile
    }
    
    func profileUpdated(profile: Profile) {
        self.profile = profile
    }
}
