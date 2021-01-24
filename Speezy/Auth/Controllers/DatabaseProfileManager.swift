//
//  UserProfileEditor.swift
//  Speezy
//
//  Created by Matt Beaney on 30/12/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import UIKit
import Foundation
import FirebaseDatabase
import FirebaseStorage

class DatabaseProfileManager {
    func fetchProfile(
        userId: String,
        completion: @escaping (Result<Profile, Error>) -> Void
    ) {
        let ref = Database.database().reference()
        ref.child("users").child(userId).child("profile").observeSingleEvent(of: .value) { (snapshot) in
            guard
                let result = snapshot.value as? NSDictionary,
                let profile = Profile(dict: result)
            else {
                assertionFailure("Something went wrong here")
                return
            }
            
            completion(.success(profile))
        }
    }
    
    func fetchProfile(
        userName: String,
        completion: @escaping (Result<(Profile, String), Error>) -> Void
    ) {
        let ref = Database.database().reference()
        ref.child("usernames").child(userName).observeSingleEvent(of: .value) { (snapshot) in
            guard let userId = snapshot.value as? String else {
                let error = NSError(domain: "database", code: 404, userInfo: nil)
                completion(.failure(error))
                return
            }
            
            self.fetchProfile(userId: userId) { (result) in
                switch result {
                case let .success(profile):
                    completion(.success((profile, userId)))
                case let .failure(error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    func checkUsernameExists(
        userName: String,
        completion: @escaping (Result<Bool, Error>) -> Void
    ) {
        let ref = Database.database().reference()
        ref.child("usernames").child(userName).observeSingleEvent(of: .value) { (snapshot) in
            if snapshot.value != nil {
                completion(.success(false))
                return
            }
            
            completion(.success(true))
        }
    }
    
    func updateUserProfile(
        userId: String,
        profile: Profile,
        profileImage: UIImage?,
        completion: @escaping (AuthResult) -> Void
    ) {
        if let profileImage = profileImage {
            uploadImageAndCreateProfile(
                userId: userId,
                profile: profile,
                profileImage: profileImage,
                completion: completion
            )
        } else {
            createUserProfile(
                userId: userId,
                profile: profile,
                completion: completion
            )
        }
    }
    
    private func uploadImageAndCreateProfile(
        userId: String,
        profile: Profile,
        profileImage: UIImage,
        completion: @escaping (AuthResult) -> Void
    ) {
        DispatchQueue.global().async {
            self.uploadUserImage(userId: userId, image: profileImage) { (result) in
                var updatedProfile = profile
                switch result {
                case let .success(profileImageUrl):
                    updatedProfile.profileImageUrl = profileImageUrl
                default:
                    break
                }
                
                self.createUserProfile(
                    userId: userId,
                    profile: updatedProfile,
                    completion: completion
                )
            }
        }
    }
    
    private func createUserProfile(
        userId: String,
        profile: Profile,
        completion: @escaping (AuthResult) -> Void
    ) {
        let ref = Database.database().reference()
        
        var dataDictionary: [String: Any] = [
            "name": profile.name,
            "about": profile.aboutYou,
            "username": profile.userName,
            "occupation": profile.occupation
        ]
        
        if let profileImage = profile.profileImageUrl {
            dataDictionary["profile_image"] = profileImage.absoluteString
        }
        
        ref.child("users").child(userId).child("profile").setValue(dataDictionary) { (error, _) in
            if let error = error {
                let error = FormError(
                    message: "Unable to set profile, please try again\nReason: \(error.localizedDescription)",
                    field: nil
                )
                
                completion(.failure(error))
            } else {
                // Make sure to update the usernames table so we can check if a user exists or not.
                let usernamesChild = ref.child("usernames/\(profile.userName)")
                usernamesChild.setValue(userId) { (error, ref) in
                    if let error = error {
                        let error = AuthErrorFactory.authError(for: error)
                        completion(.failure(error))
                    } else {
                        completion(.success)
                    }
                }
            }
        }
    }
    
    private func uploadUserImage(
        userId: String,
        image: UIImage,
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        // Create a root reference
        let storage = FirebaseStorage.Storage.storage()
        let storageRef = storage.reference()
        
        // Create a reference to "mountains.jpg"
        let profileImagesRef = storageRef.child("profile_images/\(userId).jpg")
        
        guard let data = image.compress(to: 0.5) else {
            assertionFailure("Could not compress")
            return
        }
        
        profileImagesRef.putData(data, metadata: nil) { (metadata, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            profileImagesRef.downloadURL { (url, error) in
                if let url = url {
                    completion(.success(url))
                } else if let error = error {
                    completion(.failure(error))
                    return
                }
            }
        }
    }
}
