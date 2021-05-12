//
//  AccountDeletionManager.swift
//  Speezy
//
//  Created by Matt Beaney on 18/03/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation
import FirebaseDatabase
import FirebaseAuth

class AccountDeletionManager {
    static func deleteAccountInformation(
        userId: String,
        completion: @escaping (Result<Bool, Error>) -> Void
    ) {        
        let ref = Database.database().reference()
        let userNode = ref.child("users/\(userId)")
        userNode.observe(.value) { (snapshot) in
            guard let result = snapshot.value as? NSDictionary else {
                return
            }
            
            var updatedData: [String: Any] = [:]
            
            let chats = result["chats"] as? [String: Any]
            let profile = result["profile"] as? [String: Any]
            let recordings = result["audio_clips"] as? [String: Any]
            let favourites = result["favourites"] as? [String: Any]
            let contacts = result["contacts"] as? [String: Any]
            
            // Remove user from chats and chatter groups
            chats?.keys.forEach {
                updatedData["chats/\($0)/read_by/\(userId)"] = NSNull()
                updatedData["chats/\($0)/push_tokens/\(userId)"] = NSNull()
                updatedData["chats/\($0)/chatters/\(userId)"] = NSNull()
                
                // Legacy.
                updatedData["chatters/\($0)/\(userId)"] = NSNull()
            }
            
            recordings?.keys.forEach {
                CloudAudioManager.deleteAudioClip(id: $0)
            }
            
            favourites?.keys.forEach {
                CloudAudioManager.deleteAudioClip(id: $0)
            }
            
            contacts?.keys.forEach {
                updatedData["users/\($0)/contacts/\(userId)"] = NSNull()
            }
                        
            if (profile?["profile_image"] as? String) != nil {
                CloudImageManager.deleteImage(at: "profile_images/\(userId).jpg") { _ in }
            }
            
            if let username = profile?["username"] as? String {
                updatedData["usernames/\(username.lowercased())"] = NSNull()
            }
            
            updatedData["users/\(userId)"] = NSNull()
            
            ref.updateChildValues(updatedData) { (error, updatedRef) in
                if let error = error {
                    completion(.failure(error))
                } else {
                    self.deleteMessageInformation(userId: userId) {
                        Auth.auth().currentUser?.delete(completion: { (error) in
                            if let error = error {
                                completion(.failure(error))
                            } else {
                                completion(.success(true))
                            }
                        })
                    }
                }
            }
        }
    }
    
    static func deleteMessageInformation(
        userId: String,
        completion: @escaping () -> Void
    ) {
        let ref = Database.database().reference()
        let userNode = ref.child("user_messages/\(userId)")
        userNode.observe(.value) { (snapshot) in
            guard let result = snapshot.value as? NSDictionary else {
                return
            }
            
            var updatedData: [String: Any] = [:]
            let messages = result["messages"] as? [String: Any]
            messages?.keys.forEach {
                let split = $0.components(separatedBy: ",")
                
                if split.count == 2 {
                    updatedData["messages/\(split[0])/\(split[1])"] = NSNull()
                }
                
                guard let audioId = messages?[$0] as? String else {
                    return
                }
                
                CloudAudioManager.deleteAudioClip(id: audioId)
                
                ref.updateChildValues(updatedData) { (error, updatedRef) in
                    completion()
                }
            }
        }
    }
}
