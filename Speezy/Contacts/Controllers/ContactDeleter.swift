//
//  ContactDeleter.swift
//  Speezy
//
//  Created by Matt Beaney on 10/04/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation
import FirebaseDatabase
import FirebaseAuth

class ContactDeleter {
    func deleteContact(contact: Contact) {
        guard let userId = Auth.auth().currentUser?.uid else {
            return
        }
        
        var updatePaths: [AnyHashable: Any] = [:]
        let ref = Database.database().reference()
        
        updatePaths["users/\(userId)/contacts/\(contact.userId)"] = NSNull()
        updatePaths["users/\(contact.userId)/contacts/\(userId)"] = NSNull()
        
        ref.updateChildValues(updatePaths)
    }
}
