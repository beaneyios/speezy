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
    
    var profileImageAttachment: UIImage?
    
    func login(
        viewController: UIViewController,
        completion: @escaping (AuthResult) -> Void
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
                let error = AuthErrorFactory.authError(for: error)
                completion(.failure(error))
                return
            }
                        
            self.facebookAccessToken = accessTokenString
            self.extractUserDataForProfile(accessToken: accessTokenString, completion: completion)
        }
    }
    
    func createProfile(completion: @escaping (AuthResult) -> Void) {
        guard let accessToken = self.facebookAccessToken else {
            assertionFailure("No user ID found")
            return
        }
        
        let credential = FacebookAuthProvider.credential(
            withAccessToken: accessToken
        )
        
        
        signIn(credential: credential, completion: completion)
    }
    
    private func signIn(credential: AuthCredential, completion: @escaping (AuthResult) -> Void) {
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
    
    private func extractUserDataForProfile(
        accessToken: String,
        completion: @escaping (AuthResult) -> Void
    ) {
        let params = ["fields": "first_name, last_name, email, picture.width(1080).height(1080)"]
        GraphRequest(graphPath: "me", parameters: params).start { (connection, result, error) in
            guard let dict = result as? [String: Any] else {
                let error = AuthErrorFactory.authError(for: error)
                completion(.failure(error))
                return
            }
            
            if
                let firstName = dict["first_name"] as? String,
                let lastName = dict["last_name"] as? String
            {
                self.profile.name = "\(firstName) \(lastName)"
            }
            
            // If there's an email, we should check it isn't
            // already being used before proceeding with image
            // extraction and account creation.
            if let email = dict["email"] as? String {
                self.checkEmailNotInUse(
                    dict: dict,
                    email: email,
                    accessToken: accessToken,
                    completion: completion
                )
            } else {
                self.attemptExtractImage(
                    dict: dict,
                    completion: completion
                )
            }
        }
    }
    
    private func checkEmailNotInUse(
        dict: [String: Any],
        email: String,
        accessToken: String,
        completion: @escaping (AuthResult) -> Void
    ) {
        let credential = FacebookAuthProvider.credential(
            withAccessToken: accessToken
        )
        
        Auth.auth().fetchSignInMethods(forEmail: email) { (providers, error) in
            if let providers = providers, providers.contains(credential.provider) {
                let accountAlreadyExists = AuthError(
                    message: "This account already exists, tap sign in below",
                    field: nil
                )
                
                completion(.failure(accountAlreadyExists))
            } else {
                self.attemptExtractImage(
                    dict: dict,
                    completion: completion
                )
            }
        }
    }
    
    private func attemptExtractImage(
        dict: [String: Any],
        completion: @escaping (AuthResult) -> Void
    ) {
        if
            let pictureDict = dict["picture"] as? [String: Any],
            let dataDict = pictureDict["data"] as? [String: Any],
            let urlString = dataDict["url"] as? String,
            let url = URL(string: urlString)
        {
            URLSession.shared.dataTask(with: url) { (data, response, error) in
                guard let data = data, let image = UIImage(data: data) else {
                    let error = AuthErrorFactory.authError(for: error)
                    completion(.success)
                    return
                }
                
                self.profileImageAttachment = image
                completion(.success)
            }.resume()
        } else {
            completion(.success)
        }
    }
}
