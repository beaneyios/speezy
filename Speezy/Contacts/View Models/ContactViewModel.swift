//
//  ContactViewModel.swift
//  Speezy
//
//  Created by Matt Beaney on 02/05/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import UIKit

class ContactViewModel: ProfileViewModel {
    enum Change {
        case profileLoaded
        case loadExistingChat(Chat)
        case startNewChat(Contact)
    }
    
    var didChange: ((Change) -> Void)?
    var profile: Profile?
    var profileImageAttachment: UIImage?
    
    let profileFetcher = ProfileFetcher()
    
    private let store: Store
    private let contact: Contact
    
    init(store: Store, contact: Contact) {
        self.store = store
        self.contact = contact
    }
    
    func loadData() {
        profileFetcher.fetchProfile(userId: contact.id) { (result) in
            switch result {
            case let .success(profile):
                self.profile = profile
                self.didChange?(.profileLoaded)
            case let .failure(error):
                break
            }
        }
    }
    
    func loadChatWithContact() {
        let existingChat = store.chatStore.chats.filter {
            $0.chatters.contains { (chatter) -> Bool in
                chatter.id == self.contact.id
            } && $0.chatters.count == 2
        }.first
        
        if let existingChat = existingChat {
            didChange?(.loadExistingChat(existingChat))
        } else {
            didChange?(.startNewChat(contact))
        }
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
            
        }
    }
}
