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
        case alreadyCreated(User)
        case loggedIn
        case errored(FormError)
    }
    
    weak var anchor: UIWindow!
    
    var profile: Profile? = Profile()
    var didChange: ((Change) -> Void)?
    
    private var currentNonce: String?
    private var appleIdToken: String?
    private var user: User?
    
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
        guard let user = self.user else {
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
        
        guard let nonce = self.currentNonce else {
            let error = FormError(
                message: "Something went wrong, please try again.",
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
        
        Auth.auth().signIn(with: credential) { (result, error) in
            if let user = result?.user {                
                ProfileFetcher().fetchProfile(userId: user.uid) { (result) in
                    switch result {
                    case .success:
                        self.didChange?(.alreadyCreated(user))
                    case .failure:
                        self.user = user
                        self.didChange?(.loggedIn)
                    }
                }
            } else {
                let error = AuthErrorFactory.authError(for: error)
                self.didChange?(.errored(error))
            }
        }
    }
}

extension AppleSignupViewModel: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return anchor
    }
}
