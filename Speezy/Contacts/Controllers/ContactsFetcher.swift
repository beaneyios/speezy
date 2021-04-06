//
//  ContactsFetcher.swift
//  Speezy
//
//  Created by Matt Beaney on 05/04/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation
import FirebaseDatabase

class ContactsFetcher {
    func fetchContacts(
        userId: String,
        completion: @escaping (Result<[Contact], Error>) -> Void
    ) {
        let ref = Database.database().reference()
        let contactsChild = ref.child("users/\(userId)/contacts")
        let query = contactsChild.queryOrderedByKey()
        query.observe(.value) { (snapshot) in
            
            // First thing, send found contact.
            guard
                let result = snapshot.value as? NSDictionary
            else {
                return
            }
            
            let contacts: [Contact] = result.allKeys.compactMap {
                guard
                    let key = $0 as? String,
                    let dict = result[key] as? NSDictionary
                else {
                    return nil
                }
                
                return ContactParser.parseContact(key: key, dict: dict)
            }
            
            completion(.success(contacts))
        }
    }
}
