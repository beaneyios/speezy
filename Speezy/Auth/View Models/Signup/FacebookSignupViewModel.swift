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
    
    private var facebookAccessToken: String?
    private var email: String?
    
    var profileImageAttachment: UIImage?
    
    func login(
        viewController: UIViewController,
        completion: @escaping () -> Void
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
                assertionFailure("No access token")
                return
            }
            
            self.facebookAccessToken = accessTokenString
            self.extractUserDataForProfile(completion: completion)
        }
    }
    
    func createProfile(completion: @escaping () -> Void) {
        guard let accessToken = self.facebookAccessToken else {
            assertionFailure("No user ID found")
            return
        }
        
        let credential = FacebookAuthProvider.credential(
            withAccessToken: accessToken
        )
        
        if let email = email {
            Auth.auth().fetchSignInMethods(forEmail: email) { (providers, error) in
                if let providers = providers, providers.contains(credential.provider) {
                    // TODO: Account already exists.
                } else {
                    self.signIn(credential: credential, completion: completion)
                }
            }
        } else {
            signIn(credential: credential, completion: completion)
        }
    }
    
    private func signIn(credential: AuthCredential, completion: @escaping () -> Void) {
        Auth.auth().signIn(with: credential) { (result, error) in
            if let user = result?.user {
                if let displayName = user.displayName {
                    self.profile.name = displayName
                }
                
                FirebaseUserProfileEditor().updateUserProfile(
                    userId: user.uid,
                    profile: self.profile,
                    profileImage: self.profileImageAttachment,
                    completion: completion
                )
            }
        }
    }
    
    private func extractUserDataForProfile(completion: @escaping () -> Void) {
        let params = ["fields": "first_name, last_name, email, picture.width(1080).height(1080)"]
        GraphRequest(graphPath: "me", parameters: params).start { (connection, result, error) in
            guard let dict = result as? [String: Any] else {
                completion()
                return
            }
            
            if
                let firstName = dict["first_name"] as? String,
                let lastName = dict["last_name"] as? String
            {
                self.profile.name = "\(firstName) \(lastName)"
            }
            
            if let email = dict["email"] as? String {
                self.email = email
            }
            
            if
                let pictureDict = dict["picture"] as? [String: Any],
                let dataDict = pictureDict["data"] as? [String: Any],
                let urlString = dataDict["url"] as? String,
                let url = URL(string: urlString)
            {
                URLSession.shared.dataTask(with: url) { (data, response, error) in
                    guard let data = data, let image = UIImage(data: data) else {
                        completion()
                        return
                    }
                    
                    self.profileImageAttachment = image
                    completion()
                }.resume()
            } else {
                completion()
            }
        }
    }
}
