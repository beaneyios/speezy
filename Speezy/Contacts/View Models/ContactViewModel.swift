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
        case loading(Bool)
        case profileLoaded
        case loadExistingChat(Chat)
        case startNewChat(Contact)
        case contactDeleted
    }
    
    var didChange: ((Change) -> Void)?
    var profile: Profile?
    var profileImageAttachment: UIImage?
    
    private var currentProfile: Profile?
    
    private let profileFetcher = ProfileFetcher()
    private let contactDeleter = ContactDeleter()
    private let chatCreator = ChatCreator()
    
    private let store: Store
    private let contact: Contact
    
    init(store: Store, contact: Contact) {
        self.store = store
        self.contact = contact
    }
    
    func loadData() {
        store.contactStore.addContactListObserver(self)
        store.profileStore.addProfileObserver(self)
        
        didChange?(.loading(true))
        profileFetcher.fetchProfile(userId: contact.id) { (result) in
            switch result {
            case let .success(profile):
                self.profile = profile
                self.didChange?(.profileLoaded)
            case let .failure(error):
                break
            }
            
            self.didChange?(.loading(false))
        }
    }
    
    func deleteContact() {
        didChange?(.loading(true))
        contactDeleter.deleteContact(contact: contact)
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
            createChat()
        }
    }
    
    func createChat() {
        didChange?(.loading(true))
        guard
            let currentProfile = currentProfile,
            let newChatId = chatCreator.newChatId()
        else {
            assertionFailure("No chat id")
            return
        }
        
        let currentChatter = Chatter(
            id: currentProfile.userId,
            displayName: currentProfile.name,
            profileImageUrl: currentProfile.profileImageUrl,
            color: UIColor.random
        )
        
        chatCreator.createChat(
            chatId: newChatId,
            title: nil,
            attachmentUrl: nil,
            currentChatter: currentChatter,
            contacts: [contact]
        ) { (result) in
            switch result {
            case let .success(chat):
                self.didChange?(.loadExistingChat(chat))
            case let .failure(error):
                break
            }
        }
    }
}

extension ContactViewModel: ContactListObserver {
    func contactRemoved(contact: Contact, contacts: [Contact]) {
        if contact.id == self.contact.id {
            didChange?(.contactDeleted)
            didChange?(.loading(false))
        }
    }
    
    func contactAdded(contact: Contact, in contacts: [Contact]) {}
    func contactUpdated(contact: Contact, in contacts: [Contact]) {}
    func initialContactsReceived(contacts: [Contact]) {}
    func allContacts(contacts: [Contact]) {}
}

extension ContactViewModel: ProfileObserver {
    func initialProfileReceived(profile: Profile) {
        self.currentProfile = profile
    }
    
    func profileUpdated(profile: Profile) {
        self.currentProfile = profile
    }
}
