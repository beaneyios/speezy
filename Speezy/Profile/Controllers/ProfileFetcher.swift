//
//  ProfileFetcher.swift
//  Speezy
//
//  Created by Matt Beaney on 13/02/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation
import FirebaseDatabase

class ProfileFetcher {
    
    func fetchProfile(
        userId: String,
        completion: @escaping (Result<Profile, Error>) -> Void
    ) {
        let ref = Database.database().reference()
        ref.child("users/\(userId)/profile").observeSingleEvent(of: .value) { (snapshot) in
            guard
                let result = snapshot.value as? NSDictionary,
                let profile = Profile(key: userId, dict: result)
            else {
                assertionFailure("Something went wrong here")
                return
            }
            
            completion(.success(profile))
        }
    }
    
    func fetchProfile(
        username: String,
        completion: @escaping (Result<(Profile, String), Error>) -> Void
    ) {
        let ref = Database.database().reference()
        ref.child("usernames/\(username)").observeSingleEvent(of: .value) { (snapshot) in
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
}
