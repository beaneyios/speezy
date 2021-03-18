//
//  ContactStore.swift
//  Speezy
//
//  Created by Matt Beaney on 06/02/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation

class ContactStore {
    private let contactListener = ContactsListener()
    private(set) var contacts = [Contact]()
    
    private var observations = [ObjectIdentifier : ContactListObservation]()
    private let serialQueue = DispatchQueue(label: "com.speezy.contactStoreActions")
    
    func clear() {
        self.contactListener.stopListening()
        self.contacts = []
        self.observations = [:]
    }
    
    func listenForContacts(userId: String) {
        contactListener.didChange = { change in
            // We do not want to manipulate the contacts available until the notifier has
            // finished notifying any newly added observers, so we need a queue.
            self.serialQueue.async {
                switch change {
                case let .contactAdded(contact):
                    self.handleContactAdded(contact: contact)
                case let .contactUpdated(change):
                    self.handleContactUpdated(change: change)
                case let .contactRemoved(id):
                    self.handleContactRemoved(contactId: id)
                }
            }
        }
        
        contactListener.listenForContactAdditions(userId: userId)
        contactListener.listenForContactDeletions(userId: userId)
    }
    
    private func handleContactAdded(contact: Contact) {
        if contacts.contains(contact) {
            return
        }
        
        contacts.append(contact)
        sortContacts()
        notifyObservers(change: .contactAdded(contact: contact, contacts: contacts))
    }
    
    private func handleContactUpdated(change: ContactValueChange) {
        // Find the contact to update.
        let contactToUpdate = contacts.first {
            change.contactId == $0.userId
        }
        
        // Apply the change.
        let newContact: Contact? = {
            switch change.contactValue {
            case let .displayName(displayName):
                return contactToUpdate?.withDisplayName(displayName)
            case let .profilePhotoUrl(profilePhotoUrl):
                return contactToUpdate?.withProfilePhotoUrl(URL(string: profilePhotoUrl))
            case let .userName(userName):
                return contactToUpdate?.withUserName(userName)
            }
        }()
        
        // Replace the old contact with the new one.
        if let newContact = newContact {
            replaceContact(contact: newContact)
            sortContacts()
            notifyObservers(change: .contactUpdated(contact: newContact, contacts: contacts))
        }
    }
    
    private func handleContactRemoved(contactId: String) {
        guard let contact = contacts.first(withId: contactId) else {
            return
        }
        
        contacts = contacts.removing(contact)
        sortContacts()
        notifyObservers(change: .contactRemoved(contact: contact, contacts: contacts))
    }
    
    private func replaceContact(contact: Contact) {
        contacts = contacts.replacing(contact)
    }
    
    private func sortContacts() {
        contacts = contacts.sorted(by: { (contact1, contact2) -> Bool in
            contact1.displayName.uppercased() < contact2.displayName.uppercased()
        })
    }
}

extension ContactStore {
    enum Change {
        case contactAdded(contact: Contact, contacts: [Contact])
        case contactUpdated(contact: Contact, contacts: [Contact])
        case initialContacts(contacts: [Contact])
        case contactRemoved(contact: Contact, contacts: [Contact])
    }
    
    func addContactListObserver(_ observer: ContactListObserver) {
        serialQueue.async {
            let id = ObjectIdentifier(observer)
            self.observations[id] = ContactListObservation(observer: observer)
            
            // We might be mid-load, let's give the new subscriber what we have so far.
            observer.initialContactsReceived(contacts: self.contacts)
        }
    }
    
    func removeContactListObserver(_ observer: ContactListObserver) {
        serialQueue.async {
            let id = ObjectIdentifier(observer)
            self.observations.removeValue(forKey: id)
        }
    }
    
    private func notifyObservers(change: Change) {
        observations.forEach {
            guard let observer = $0.value.observer else {
                observations.removeValue(forKey: $0.key)
                return
            }
            
            switch change {
            case let .contactAdded(contact, contacts):
                observer.contactAdded(contact: contact, in: contacts)
            case let .contactUpdated(contact, contacts):
                observer.contactUpdated(contact: contact, in: contacts)
            case let .initialContacts(contacts):
                observer.initialContactsReceived(contacts: contacts)
            case let .contactRemoved(contact, contacts):
                observer.contactRemoved(contact: contact, contacts: contacts)
            }
        }
    }
}
