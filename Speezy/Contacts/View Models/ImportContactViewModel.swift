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
        case contactImported(Contact)
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
                self.addContact(userContact: userContact, profile: profile)
            case let .failure(error):
                break
            }
        }
    }
    
    private func addContact(userContact: Contact, profile: Profile) {
        let contact = profile.toContact
        self.contactManager.addContact(userContact: userContact, contact: contact) { (result) in
            switch result {
            case let .success(contact):
                self.didChange?(.contactImported(contact))
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
