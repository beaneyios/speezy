//
//  DatabaseContactManager.swift
//  Speezy
//
//  Created by Matt Beaney on 23/01/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation
import FirebaseDatabase

class DatabaseContactManager {
    var currentQuery: DatabaseQuery?
    
    func fetchContacts(
        userId: String,
        completion: @escaping (Result<[Contact], Error>) -> Void
    ) {
        let ref = Database.database().reference()
        let chattersChild: DatabaseReference = ref.child("users/\(userId)/contacts")
        
        chattersChild.observeSingleEvent(of: .value) { (snapshot) in
            guard let result = snapshot.value as? NSDictionary else {
                completion(.success([]))
                return
            }
            
            let contacts: [Contact] = result.allKeys.compactMap {
                guard
                    let key = $0 as? String,
                    let dict = result[key] as? NSDictionary
                else {
                    return nil
                }
                
                return DatabaseContactParser.parseContact(key: key, dict: dict)
            }
            
            completion(.success(contacts))
        } withCancel: { (error) in
            completion(.failure(error))
        }
    }
}
