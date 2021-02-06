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
    
    let tokenSyncService = PushTokenSyncService()
    
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
                if result?.isCancelled == true {
                    completion(.failure(nil))
                    return
                }
                
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
        
        DatabaseProfileManager().checkUsernameExists(userName: profile.userName) { (result) in
            switch result {
            case let .success(exists):
                if exists {
                    let error = FormError(message: "Username already exists", field: .username)
                    completion(.failure(error))
                } else {
                    self.createUserInFirebase(token: accessToken, completion: completion)
                }
            case let .failure(error):
                let error = AuthErrorFactory.authError(for: error)
                completion(.failure(error))
            }
        }
    }
    
    private func createUserInFirebase(token: String, completion: @escaping (AuthResult) -> Void) {
        let credential = FacebookAuthProvider.credential(
            withAccessToken: token
        )
        
        Auth.auth().signIn(with: credential) { (result, error) in
            if let user = result?.user {
                if let displayName = user.displayName {
                    self.profile.name = displayName
                }
                
                DatabaseProfileManager().updateUserProfile(
                    userId: user.uid,
                    profile: self.profile,
                    profileImage: self.profileImageAttachment
                ) { (result) in
                    switch result {
                    case .success:                        
                        Store.shared.startListeningForCoreChanges(userId: user.uid)
                        self.tokenSyncService.syncPushToken(userId: user.uid)
                        completion(.success)
                    case let .failure(error):
                        completion(.failure(error))
                    }
                }
            } else {
                let formError = AuthErrorFactory.authError(for: error)
                completion(.failure(formError))
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
                let accountAlreadyExists = FormError(
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
