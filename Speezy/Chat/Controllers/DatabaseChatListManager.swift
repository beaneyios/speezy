//
//  DatabaseChatListManager.swift
//  Speezy
//
//  Created by Matt Beaney on 23/01/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation
import FirebaseDatabase

class DatabaseChatListManager {
    func fetchChats(
        userId: String,
        completion: @escaping (Result<[Chat], Error>) -> Void
    ) {
        let ref = Database.database().reference()
        let chatsChild: DatabaseReference = ref.child("users/\(userId)/chats")
        let query = chatsChild.queryOrderedByKey()
        query.observeSingleEvent(of: .value) { (snapshot) in
            guard let result = snapshot.value as? NSDictionary else {
                completion(.success([]))
                return
            }
            
            let chatIds: [String] = result.allKeys.compactMap {
                $0 as? String
            }
            
            let chats = self.fetchChats(forChatIds: chatIds) { chats in
                completion(.success(chats))
            }
        } withCancel: { (error) in
            completion(.failure(error))
        }
    }
    
    private func fetchChats(
        forChatIds ids: [String],
        completion: @escaping ([Chat]) -> Void
    ) {
        var chats = [Chat]()
        let group = DispatchGroup()
        
        ids.forEach {
            group.enter()
            let ref = Database.database().reference()
            let chatChild: DatabaseReference = ref.child("chats/\($0)")
            chatChild.observeSingleEvent(of: .value) { (snapshot) in
                guard let result = snapshot.value as? NSDictionary else {
                    group.leave()
                    return
                }
                
                guard let chat = DatabaseChatParser.parseChat(key: snapshot.key, dict: result) else {
                    group.leave()
                    return
                }
                
                chats.append(chat)
                group.leave()
            }
        }
        
        group.notify(queue: DispatchQueue.global()) {
            completion(chats)
        }
    }
}
