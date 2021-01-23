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
    private(set) var items = [ContactCellModel]()
    var didChange: ((Change) -> Void)?
    let contactListManager = DatabaseContactManager()
    let chatManager = DatabaseChatManager()
    
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
    
    func selectContact(contact: Contact) {
        if let contactIndex = selectedContacts.firstIndex(of: contact) {
            selectedContacts.remove(at: contactIndex)
        } else {
            selectedContacts.append(contact)
        }
    }
    
    func createChat() {
        chatManager.createChat(
            title: "",
            currentChatter: Chatter(id: "", displayName: "", profileImageUrl: nil),
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
