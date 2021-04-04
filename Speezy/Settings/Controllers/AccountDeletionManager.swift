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
            
            var updatedData: [String: Any] = [
                :
            ]
            
            let chats = result["chats"] as? [String: Any]
            let profile = result["profile"] as? [String: Any]
            let recordings = result["audio_clips"] as? [String: Any]
            let favourites = result["favourites"] as? [String: Any]
            let contacts = result["contacts"] as? [String: Any]
            let messages = result["messages"] as? [String: Any]
            
            // Remove user from chats and chatter groups
            chats?.keys.forEach {
                updatedData["chats/\($0)/read_by/\(userId)"] = NSNull()
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
            
            messages?.keys.forEach {
                guard let asString = $0 as? String else {
                    return
                }
                
                let split = asString.components(separatedBy: ",")
                
                if split.count == 2 {
                    updatedData["messages/\(split[0])/\(split[1])"] = NSNull()
                }
                
                guard let audioId = messages?[asString] as? String else {
                    return
                }
                
                CloudAudioManager.deleteAudioClip(id: audioId)
            }
            
            if (profile?["profile_image"] as? String) != nil {
                CloudImageManager.deleteImage(at: "profile_images/\(userId).jpg") { _ in }
            }
            
            if let username = profile?["username"] as? String {
                updatedData["usernames/\(username)"] = NSNull()
            }
            
            updatedData["users/\(userId)"] = NSNull()
            
            ref.updateChildValues(updatedData) { (error, updatedRef) in
                if let error = error {
                    completion(.failure(error))
                } else {
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
