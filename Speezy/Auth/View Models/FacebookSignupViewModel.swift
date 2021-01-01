//
//  FacebookSignupViewModel.swift
//  Speezy
//
//  Created by Matt Beaney on 24/12/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import Foundation
import FBSDKCoreKit
import FBSDKLoginKit
import FirebaseAuth

class FacebookSignupViewModel: FirebaseSignupViewModel {
    var profile: Profile = Profile()
    var userId: String?
    
    func login(
        viewController: UIViewController,
        completion: @escaping (Result<User, Error>) -> Void
    ) {
        let manager = LoginManager()
        manager.logIn(
            permissions: ["public_profile", "email"],
            from: viewController
        ) { (result, error) in
            guard
                result != nil,
                let accessTokenString = AccessToken.current?.tokenString
            else {
                return
            }
            
            let credential = FacebookAuthProvider.credential(
                withAccessToken: accessTokenString
            )
            
            Auth.auth().signIn(with: credential) { (result, error) in
                if let user = result?.user {
                    if let displayName = user.displayName {
                        self.profile.name = displayName
                    }
                    
                    self.userId = user.uid
                    completion(.success(user))
                }
                
                // TODO: Catch pre-existing accounts.
            }
        }
    }
    
    func createProfile(completion: @escaping () -> Void) {
        guard let userId = self.userId else {
            assertionFailure("No user ID found")
            return
        }
        
        FirebaseUserProfileEditor().updateUserProfile(
            userId: userId,
            profile: profile,
            completion: completion
        )
    }
}
