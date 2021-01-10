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
        case errored(AuthError)
    }
    
    weak var anchor: UIWindow!
    
    var profile: Profile = Profile()
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
    
    func createProfile(completion: @escaping (AuthResult) -> Void) {
        guard let idTokenString = appleIdToken, let nonce = currentNonce else {
            return
        }
        
        // Initialize a Firebase credential.
        let credential = OAuthProvider.credential(
            withProviderID: "apple.com",
            idToken: idTokenString,
            rawNonce: nonce
        )
        
        // Sign in with Firebase.
        Auth.auth().signIn(with: credential) { (authResult, error) in
            if let user = authResult?.user {
                if let displayName = user.displayName {
                    self.profile.name = displayName
                }
                
                FirebaseUserProfileEditor().updateUserProfile(
                    userId: user.uid,
                    profile: self.profile,
                    profileImage: self.profileImageAttachment,
                    completion: completion
                )
            } else {
                let error = AuthErrorFactory.authError(for: error)
                completion(.failure(error))
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
        
        self.profile.name = {
            if let name = appleIDCredential.fullName {
                if let firstName = name.givenName, let surname = name.familyName {
                    return "\(firstName) \(surname)"
                } else if let firstName = name.givenName {
                    return "\(firstName)"
                }
            }
            
            return ""
        }()
        
        self.appleIdToken = idTokenString
        self.didChange?(.loggedIn)
    }
}

extension AppleSignupViewModel: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return anchor
    }
}
