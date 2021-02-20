//
//  ImportContactViewController.swift
//  Speezy
//
//  Created by Matt Beaney on 20/02/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation

class ImportContactViewModel {
    enum Change {
        case contactImported
    }
    
    var didChange: ((Change) -> Void)?
    
    let contactId: String
    let store: Store
    
    let contactManager = DatabaseContactManager()
    let profileFetcher = ProfileFetcher()
        
    init(contactId: String, store: Store = Store.shared) {
        self.contactId = contactId
        self.store = store
    }
    
    func loadData() {
        store.profileStore.addProfileObserver(self)
    }
    
    func importContact(userContact: Contact) {
        profileFetcher.fetchProfile(userId: contactId) { (result) in
            switch result {
            case let .success(profile):
                let contact = profile.toContact
                self.contactManager.addContact(userContact: userContact, contact: contact) { (result) in
                    self.didChange?(.contactImported)
                }
            case let .failure(error):
                break
            }
        }
    }
}

extension ImportContactViewModel: ProfileObserver {
    func initialProfileReceived(profile: Profile) {
        importContact(userContact: profile.toContact)
    }
    
    func profileUpdated(profile: Profile) {}
}
