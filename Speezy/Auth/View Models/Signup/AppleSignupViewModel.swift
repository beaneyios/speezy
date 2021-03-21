//
//  AppleSignupViewModel.swift
//  Speezy
//
//  Created by Matt Beaney on 25/12/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import Foundation
import AuthenticationServices
import FirebaseAuth

class AppleSignupViewModel: NSObject, FirebaseSignupViewModel {
    
    enum Change {
        case loggedIn
        case errored(FormError)
    }
    
    weak var anchor: UIWindow!
    
    var profile: Profile? = Profile()
    var didChange: ((Change) -> Void)?
    
    private var currentNonce: String?
    private var appleIdToken: String?
    
    var profileImageAttachment: UIImage?
    
    init(anchor: UIWindow) {
        self.anchor = anchor
    }
    
    func startSignInWithAppleFlow() {
        let nonce = String.nonce()
        currentNonce = nonce
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = String.sha256(nonce)
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
    
    func createProfile(completion: @escaping (SpeezyResult<User, FormError?>) -> Void) {
        guard let idTokenString = appleIdToken, let nonce = currentNonce else {
            return
        }
        
        let credential = OAuthProvider.credential(
            withProviderID: "apple.com",
            idToken: idTokenString,
            rawNonce: nonce
        )
        
        Auth.auth().signIn(with: credential) { (authResult, error) in
            guard let user = authResult?.user else {
                let error = AuthErrorFactory.authError(for: error)
                completion(.failure(error))
                return
            }
            
            if let displayName = user.displayName {
                self.profile?.name = displayName
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
                case .success:
                    completion(.success(user))
                case let .failure(error):
                    completion(.failure(error))
                }
            }
        }
    }
}

extension AppleSignupViewModel: ASAuthorizationControllerDelegate {
    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        let error = AuthErrorFactory.authError(for: error)
        didChange?(.errored(error))
    }
    
    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard
            let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
            let appleIDToken = appleIDCredential.identityToken,
            let idTokenString = String(data: appleIDToken, encoding: .utf8)
        else {
            assertionFailure("Unable to fetch token")
            return
        }
        
        self.profile?.name = {
            if let name = appleIDCredential.fullName {
                if let firstName = name.givenName, let surname = name.familyName {
                    return "\(firstName) \(surname)"
                } else if let firstName = name.givenName {
                    return "\(firstName)"
                }
            }
            
            return ""
        }()
        
        guard let email = appleIDCredential.email, let nonce = self.currentNonce else {
            let error = FormError(
                message: "It looks like you've used this account to sign up already, try logging in instead.",
                field: nil
            )
            
            didChange?(.errored(error))
            return
        }
        
        let credential = OAuthProvider.credential(
            withProviderID: "apple.com",
            idToken: idTokenString,
            rawNonce: nonce
        )
        
        checkEmailNotInUse(email: email, credential: credential) { (error) in
            if let error = error {
                self.didChange?(.errored(error))
                return
            }
            
            self.appleIdToken = idTokenString
            self.didChange?(.loggedIn)
        }
    }
    
    private func checkEmailNotInUse(email: String, credential: AuthCredential, completion: @escaping (FormError?) -> Void) {
        Auth.auth().fetchSignInMethods(forEmail: email) { (providers, error) in
            if let providers = providers, providers.contains(credential.provider) {
                let accountAlreadyExists = FormError(
                    message: "This account already exists, tap sign in below",
                    field: nil
                )
                
                completion(accountAlreadyExists)
            } else {
                completion(nil)
            }
        }
    }
}

extension AppleSignupViewModel: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return anchor
    }
}
