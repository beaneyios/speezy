//
//  ChattersFetcher.swift
//  Speezy
//
//  Created by Matt Beaney on 21/02/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation
import FirebaseDatabase

class ChattersFetcher {
    func fetchChatters(
        chat: Chat,
        completion: @escaping (Result<[Chatter], Error>) -> Void
    ) {
        let ref = Database.database().reference()
        let chattersChild: DatabaseReference = ref.child("chatters/\(chat.id)")
        
        chattersChild.observeSingleEvent(of: .value) { (snapshot) in
            guard let result = snapshot.value as? NSDictionary else {
                completion(.success([]))
                return
            }
            
            let chatters: [Chatter] = result.allKeys.compactMap {
                guard
                    let key = $0 as? String,
                    let dict = result[key] as? NSDictionary
                else {
                    return nil
                }
                
                return ChatParser.parseChatter(key: key, dict: dict)
            }
            
            completion(.success(chatters))
        } withCancel: { (error) in
            completion(.failure(error))
        }
    }
}
