//
//  AppleLoginViewModel.swift
//  Speezy
//
//  Created by Matt Beaney on 21/03/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation
import AuthenticationServices
import FirebaseAuth

class AppleLoginViewModel: NSObject {
    enum Change {
        case loggedIn(User)
        case errored(FormError)
    }
    
    let tokenSyncService = PushTokenSyncService()
    weak var anchor: UIWindow!
    var didChange: ((Change) -> Void)?
    private var currentNonce: String?
    
    init(anchor: UIWindow) {
        self.anchor = anchor
    }
    
    func login(viewController: UIViewController) {
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
}

extension AppleLoginViewModel: ASAuthorizationControllerDelegate {
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
            let idTokenString = String(data: appleIDToken, encoding: .utf8),
            let nonce = currentNonce
        else {
            assertionFailure("Unable to fetch token")
            return
        }
        
        let credential = OAuthProvider.credential(
            withProviderID: "apple.com",
            idToken: idTokenString,
            rawNonce: nonce
        )
        
        Auth.auth().signIn(with: credential) { (result, error) in
            if let user = result?.user {
                self.didChange?(.loggedIn(user))
            } else {
                let error = AuthErrorFactory.authError(for: error)
                self.didChange?(.errored(error))
            }
        }
    }
}

extension AppleLoginViewModel: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return anchor
    }
}
