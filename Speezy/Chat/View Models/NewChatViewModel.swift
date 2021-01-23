//
//  NewChatViewModel.swift
//  Speezy
//
//  Created by Matt Beaney on 23/01/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation
import FirebaseAuth

class NewChatViewModel {
    enum Change {
        case loaded
        case chatCreated(Chat)
    }
    
    private(set) var selectedContacts = [Contact]()
    private(set) var title: String?
    
    private(set) var items = [ContactCellModel]()
    
    var didChange: ((Change) -> Void)?
    let contactListManager = DatabaseContactManager()
    let chatManager = DatabaseChatManager()
    let profileManager = DatabaseProfileManager()
    
    func listenForData() {
        guard let userId = Auth.auth().currentUser?.uid else {
            assertionFailure("No user id")
            return
        }
        
        contactListManager.fetchContacts(userId: userId) { (result) in
            switch result {
            case let .success(contacts):
                self.items = contacts.map {
                    ContactCellModel(contact: $0, selected: self.selectedContacts.contains($0))
                }
                
                self.didChange?(.loaded)
            case let .failure(error):
                break
            }
        }
    }
    
    func setTitle(_ title: String) {
        self.title = title
    }
    
    func selectContact(contact: Contact) {
        if let contactIndex = selectedContacts.firstIndex(of: contact) {
            selectedContacts.remove(at: contactIndex)
        } else {
            selectedContacts.append(contact)
        }
    }
    
    func createChat() {
        guard let userId = Auth.auth().currentUser?.uid else {
            assertionFailure("No user id")
            return
        }
        
        profileManager.fetchProfile(userId: userId) { (result) in
            switch result {
            case let .success(profile):
                let chatter = Chatter(
                    id: userId,
                    displayName: profile.name,
                    profileImageUrl: profile.profileImageUrl
                )
                
                self.createChat(with: chatter)
            case let .failure(error):
                break
            }
        }
    }
    
    private func createChat(with chatter: Chatter) {
        guard let title = self.title else {
            return
        }
        
        chatManager.createChat(
            title: title,
            currentChatter: chatter,
            contacts: selectedContacts
        ) { (result) in
            switch result {
            case let .success(chat):
                self.didChange?(.chatCreated(chat))
            case let .failure(error):
                break
            }
        }
    }
}

extension NewChatViewModel {
    func validationError() -> FormError? {
        if title == nil || title?.isEmpty == true {
            return FormError(
                message: "Please choose a title",
                field: .chatTitle
            )
        }
        
        if selectedContacts.isEmpty {
            return FormError(
                message: "Please select at least one contact",
                field: nil
            )
        }
        
        return nil
    }
}
