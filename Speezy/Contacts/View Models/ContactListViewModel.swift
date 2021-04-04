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
        case loading(Bool)
        case replacedItem(Int)
    }
    
    private let store: Store
    private let debouncer = Debouncer(seconds: 0.5)
    private var contacts = [Contact]()
    private(set) var items = [ContactCellModel]()
    var didChange: ((Change) -> Void)?
    
    var shouldShowEmptyView: Bool {
        items.isEmpty
    }
    
    init(store: Store) {
        self.store = store
    }
    
    func listenForData() {
        guard let userId = Auth.auth().currentUser?.uid else {
            assertionFailure("No user id")
            return
        }
        
        store.contactStore.addContactListObserver(self)
    }
    
    private func updateCellModels(contacts: [Contact]) {
        debouncer.debounce {
            self.contacts = contacts
            self.items = contacts.map {
                ContactCellModel(contact: $0, selected: nil)
            }

            self.didChange?(.loaded)
            self.didChange?(.loading(false))
        }
    }
    
    private func updateCellModel(contact: Contact) {
        debouncer.debounce {
            self.contacts = self.contacts.replacing(contact)
            let newCellModel = ContactCellModel(contact: contact, selected: nil)
            self.items = self.items.replacing(newCellModel)
            
            if let index = self.contacts.firstIndex(of: contact) {
                self.didChange?(.replacedItem(index))
            } else {
                self.didChange?(.loaded)
            }
        }
    }
}

extension ContactListViewModel: ContactListObserver {
    func contactAdded(contact: Contact, in contacts: [Contact]) {
        updateCellModels(contacts: contacts)
    }
    
    func contactUpdated(contact: Contact, in contacts: [Contact]) {
        if contacts.isSameOrderAs(self.contacts) {
            updateCellModel(contact: contact)
        } else {
            updateCellModels(contacts: contacts)
        }
    }
    
    func initialContactsReceived(contacts: [Contact]) {
        updateCellModels(contacts: contacts)
    }
    
    func contactRemoved(contact: Contact, contacts: [Contact]) {
        updateCellModels(contacts: contacts)
    }
}
