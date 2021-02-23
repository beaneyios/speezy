//
//  GoogleSignInViewModel.swift
//  Speezy
//
//  Created by Matt Beaney on 21/02/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation
import Firebase
import FirebaseAuth
import GoogleSignIn

class GoogleSignInViewModel: NSObject, GIDSignInDelegate {
    enum Change {
        case errored(FormError)
        case loggedIn(User)
    }
    
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
            return
        }
        
        guard let authentication = user?.authentication else { return }
        
        let credential = GoogleAuthProvider.credential(
            withIDToken: authentication.idToken,
            accessToken: authentication.accessToken
        )
        
        self.checkEmailInUse(user: user, credential: credential)
    }
    
    private func checkEmailInUse(
        user: GIDGoogleUser,
        credential: AuthCredential
    ) {
        Auth.auth().fetchSignInMethods(forEmail: user.profile.email) { (providers, error) in
            if let providers = providers, providers.contains(credential.provider) {
                self.signIn(credential: credential)
            } else {
                let accountAlreadyExists = FormError(
                    message: "This account doesn't exist, please use the signup screen",
                    field: nil
                )
                
                self.didChange?(.errored(accountAlreadyExists))
            }
        }
    }
    
    private func signIn(credential: AuthCredential) {
        Auth.auth().signIn(with: credential) { (result, error) in
            if let error = error {
                let formError = AuthErrorFactory.authError(for: error)
                self.didChange?(.errored(formError))
                return
            }
            
            guard let user = result?.user else {
                let formError = AuthErrorFactory.authError(for: error)
                self.didChange?(.errored(formError))
                return
            }

            self.didChange?(.loggedIn(user))
        }
    }
}
