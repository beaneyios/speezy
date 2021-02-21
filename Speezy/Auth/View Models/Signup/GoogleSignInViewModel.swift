//
//  GoogleSignupViewModel.swift
//  Speezy
//
//  Created by Matt Beaney on 21/02/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation
import GoogleSignIn
import Firebase

class GoogleSignInViewModel: NSObject, GIDSignInDelegate, FirebaseSignupViewModel {
    enum Change {
        case errored(FormError)
        case success(Profile)
    }
    
    var profile: Profile? = Profile()
    var profileImageAttachment: UIImage?
    var didChange: ((Change) -> Void)?
    
    private var credential: AuthCredential?
    
    override init() {
        super.init()
        GIDSignIn.sharedInstance().clientID = FirebaseApp.app()?.options.clientID
        GIDSignIn.sharedInstance().delegate = self
    }
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if let error = error {
            let formError = AuthErrorFactory.authError(for: error)
            didChange?(.errored(formError))
        }
        
        guard let authentication = user.authentication else { return }
        
        let credential = GoogleAuthProvider.credential(
            withIDToken: authentication.idToken,
            accessToken: authentication.accessToken
        )
        
        self.checkEmailNotInUse(user: user, credential: credential)
    }
    
    private func checkEmailNotInUse(
        user: GIDGoogleUser,
        credential: AuthCredential
    ) {
        Auth.auth().fetchSignInMethods(forEmail: user.profile.email) { (providers, error) in
            if let providers = providers, providers.contains(credential.provider) {
                let accountAlreadyExists = FormError(
                    message: "This account already exists, tap sign in below",
                    field: nil
                )
                
                self.didChange?(.errored(accountAlreadyExists))
            } else {
                self.credential = credential
                self.extractUserDataForProfile(user: user)
            }
        }
    }
    
    private func extractUserDataForProfile(user: GIDGoogleUser) {
        let name: String = {
            if let givenName = user.profile.givenName {
                if let familyName = user.profile.familyName {
                    return "\(givenName) \(familyName)"
                }
                
                return givenName
            } else {
                return ""
            }
        }()
        
        profile?.name = name
        
        if user.profile.hasImage {
            downloadImage(url: user.profile.imageURL(withDimension: 100))
        } else {
            completeWithProfile()
        }
    }
    
    private func downloadImage(url: URL) {
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard let data = data, let image = UIImage(data: data) else {
                return
            }
            
            self.profileImageAttachment = image
            self.completeWithProfile()
        }.resume()
    }
    
    private func completeWithProfile() {
        guard let profile = profile else {
            return
        }
        
        didChange?(.success(profile))
    }
}

// MARK: Profile creation
extension GoogleSignInViewModel {
    func createProfile(completion: @escaping (SpeezyResult<User, FormError?>) -> Void) {
        guard let profile = self.profile else {
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
                    self.createUserInFirebase(completion: completion)
                }
            case let .failure(error):
                let error = AuthErrorFactory.authError(for: error)
                completion(.failure(error))
            }
        }
    }
    
    private func createUserInFirebase(completion: @escaping (SpeezyResult<User, FormError?>) -> Void) {
        guard let credential = self.credential else {
            return
        }
        
        Auth.auth().signIn(with: credential) { (result, error) in
            if let error = error {
                let formError = AuthErrorFactory.authError(for: error)
                completion(.failure(formError))
                return
            }
            
            guard let user = result?.user else {
                let formError = AuthErrorFactory.authError(for: error)
                completion(.failure(formError))
                return
            }
            
            guard let profile = self.profile else {
                return
            }
            
            DatabaseProfileManager().updateUserProfile(
                userId: user.uid,
                profile: profile,
                profileImage: self.profileImageAttachment
            ) { (result) in
                switch result {
                case let .success(profile):
                    completion(.success(user))
                case let .failure(error):
                    if let error = error {
                        completion(.failure(error))
                    }
                }
            }
        }
    }
}
