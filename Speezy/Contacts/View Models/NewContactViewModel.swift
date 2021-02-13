//
//  NewContactViewModel.swift
//  Speezy
//
//  Created by Matt Beaney on 24/01/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation
import FirebaseDatabase
import FirebaseAuth

class NewContactViewModel {
    enum Change {
        case loading(Bool)
        case userLoaded
        case loaded
        case contactAdded(Contact)
    }
    
    var didChange: ((Change) -> Void)?
    
    private(set) var userName: String = ""
    private(set) var items = [ContactCellModel]()
    
    private var currentContact: Contact?
    
    private let debouncer = Debouncer(seconds: 1.5)
    
    private let profileFetcher = ProfileFetcher()
    private let profileManager = DatabaseProfileManager()
    private let contactManager = DatabaseContactManager()
    
    var shouldShowEmptyView: Bool {
        !userName.isEmpty && items.isEmpty
    }
    
    func loadData() {
        guard let id = Auth.auth().currentUser?.uid else {
            return
        }
        
        didChange?(.loading(true))
        profileFetcher.fetchProfile(userId: id) { (result) in
            switch result {
            case let .success(profile):
                self.currentContact = Contact(
                    userId: id,
                    displayName: profile.name,
                    userName: profile.userName,
                    profilePhotoUrl: profile.profileImageUrl
                )
                
                self.didChange?(.userLoaded)
            case let .failure(error):
                break
            }
            
            self.didChange?(.loading(false))
        }
    }
    
    func setUserName(userName: String) {
        self.userName = userName
    
        guard userName.count > 3 else {
            debouncer.cancel()
            return
        }
        
        debouncer.debounce {
            self.didChange?(.loading(true))
            self.profileFetcher.fetchProfile(username: userName) { (result) in
                switch result {
                case let .success((profile, userId)):
                    let contact = Contact(
                        userId: userId,
                        displayName: profile.name,
                        userName: profile.userName,
                        profilePhotoUrl: profile.profileImageUrl
                    )
                    
                    self.items = [
                        ContactCellModel(
                            contact: contact,
                            selected: nil
                        )
                    ]
                case let .failure(error):
                    self.items = []
                }
                
                self.didChange?(.loaded)
                self.didChange?(.loading(false))
            }
        }
    }
    
    func addContact(contact: Contact) {
        guard let userContact = self.currentContact else {
            return
        }
        
        contactManager.addContact(
            userContact: userContact,
            contact: contact
        ) { (result) in
            switch result {
            case let .success(contact):
                self.didChange?(.contactAdded(contact))
            case let .failure(error):
                break
            }
        }
    }
}
