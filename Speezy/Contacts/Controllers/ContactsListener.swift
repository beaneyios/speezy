//
//  ContactsListener.swift
//  Speezy
//
//  Created by Matt Beaney on 06/02/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation
import FirebaseDatabase

class ContactsListener {
    enum Change {
        case contactAdded(Contact)
        case contactUpdated(ContactValueChange)
        case contactRemoved(String)
    }
        
    var didChange: ((Change) -> Void)?
    
    var queries: [String: DatabaseQuery] = [:]
    
    func listenForContactAdditions(userId: String) {
        let ref = Database.database().reference()
        let contactsChild = ref.child("users/\(userId)/contacts")
        let query = contactsChild.queryOrderedByKey().queryLimited(toLast: 1)
        query.observe(.childAdded) { (snapshot) in
            
            // First thing, send found contact.
            guard
                let dict = snapshot.value as? NSDictionary,
                let contact = ContactParser.parseContact(key: snapshot.key, dict: dict)
            else {
                return
            }
            
            self.didChange?(.contactAdded(contact))
            
            // Second thing - listen for any future changes to the contact.
            self.listenForContactChanges(userId: userId, contactId: snapshot.key)
        }
        
        queries["additions"] = query
    }
    
    func listenForContactDeletions(userId: String) {
        let ref = Database.database().reference()
        let contactsChild = ref.child("users/\(userId)/contacts")
        let query = contactsChild.queryOrderedByKey()
        query.observe(.childRemoved) { (snapshot) in
            self.didChange?(.contactRemoved(snapshot.key))
        }
        
        queries["deletions"] = query
    }
    
    func stopListening() {
        queries.forEach {
            $0.value.removeAllObservers()
        }
        
        queries = [:]
    }
    
    private func listenForContactChanges(userId: String, contactId: String) {
        let ref = Database.database().reference()
        let contactsChild: DatabaseReference = ref.child("users/\(userId)/contacts/\(contactId)")
        let query = contactsChild.queryOrderedByKey()
        query.observe(.childChanged) { (snapshot) in
            guard
                let value = snapshot.value,
                let contactValue = ContactValue(key: snapshot.key, value: value)
            else {
                return
            }
            
            
            let change = ContactValueChange(contactId: contactId, contactValue: contactValue)
            self.didChange?(.contactUpdated(change))
        }
        
        queries["changes"] = query
    }
}
