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
        case loggedIn(User)
    }
    
    weak var anchor: UIWindow!
    
    var profile: Profile = Profile()
    var didChange: ((Change) -> Void)?
    private var currentNonce: String?
    
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
    
    func createProfile(completion: @escaping () -> Void) {
        // TODO: Once DB is created, create a profile
        completion()
    }
}

extension AppleSignupViewModel: ASAuthorizationControllerDelegate {
    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        
    }
    
    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard
            let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential
        else {
            return
        }
        
        guard let nonce = currentNonce else {
            assertionFailure(
                "Invalid state: A login callback was received, but no login request was sent."
            )
            return
        }
        
        guard let appleIDToken = appleIDCredential.identityToken else {
            assertionFailure("Unable to fetch identity token")
            return
        }
        
        guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            assertionFailure(
                "Unable to serialize token string from data: \(appleIDToken.debugDescription)"
            )
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
            if let error = error {
                // Error. If error.code == .MissingOrInvalidNonce, make sure
                // you're sending the SHA256-hashed nonce as a hex string with
                // your request to Apple.
                print(error.localizedDescription)
            } else if let result = authResult {
                if let displayName = result.user.displayName {
                    self.profile.name = displayName
                }
                
                self.didChange?(.loggedIn(result.user))
            }
        }
    }
}

extension AppleSignupViewModel: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return anchor
    }
}
