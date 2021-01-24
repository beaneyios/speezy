//
//  ContactListViewModel.swift
//  Speezy
//
//  Created by Matt Beaney on 23/01/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation
import FirebaseAuth

class ContactListViewModel {
    enum Change {
        case loaded
    }
    
    private(set) var items = [ContactCellModel]()
    var didChange: ((Change) -> Void)?
    let contactListManager = DatabaseContactManager()
    
    func listenForData() {
        guard let userId = Auth.auth().currentUser?.uid else {
            assertionFailure("No user id")
            return
        }
        
        contactListManager.fetchContacts(userId: userId) { (result) in
            switch result {
            case let .success(contacts):
                self.items = contacts.map {
                    ContactCellModel(contact: $0, selected: nil)
                }.sorted {
                    $0.contact.displayName < $1.contact.displayName
                }
                
                self.didChange?(.loaded)
            case let .failure(error):
                break
            }
        }
    }
    
    func insertNewContactItem(contact: Contact) {
        let newCellModel = ContactCellModel(contact: contact, selected: nil)
        if items.isEmpty {
            items.append(newCellModel)
        } else {
            items.insert(newCellModel, at: 0)
        }
        
        items.sort {
            $0.contact.displayName < $1.contact.displayName
        }
        
        didChange?(.loaded)
    }
}

