//
//  ProfileEditViewModel.swift
//  Speezy
//
//  Created by Matt Beaney on 16/02/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import UIKit

class ProfileEditViewModel: ProfileViewModel {
    enum Change {
        case profileLoaded
        case saved
    }
    
    var didChange: ((Change) -> Void)?
    var profile: Profile?
    var profileImageAttachment: UIImage?
    
    var contact: Contact? {
        profile?.toContact
    }
    
    private let store: Store
    
    init(store: Store) {
        self.store = store
    }
    
    func loadData() {
        store.profileStore.addProfileObserver(self)
    }
    
    func updateProfile() {
        guard let profile = profile else {
            return
        }
        
        DatabaseProfileManager().updateUserProfile(
            userId: profile.userId,
            profile: profile,
            profileImage: profileImageAttachment
        ) { (result) in
            self.didChange?(.saved)
        }
    }
}

extension ProfileEditViewModel: ProfileObserver {
    func initialProfileReceived(profile: Profile) {
        self.profile = profile
        
        CloudImageManager.fetchImage(
            at: "profile_images/\(profile.userId).jpg"
        ) { (result) in
            switch result {
            case let .success(image):
                self.profileImageAttachment = image
            case .failure:
                break
            }
            
            self.didChange?(.profileLoaded)
        }
    }
    
    func profileUpdated(profile: Profile) {
        self.profile = profile
    }
}
