//
//  FacebookLoginViewModel.swift
//  Speezy
//
//  Created by Matt Beaney on 09/01/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation
import FBSDKCoreKit
import FBSDKLoginKit
import FirebaseAuth

class FacebookLoginViewModel {        
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
                return
            }
            
            let credential = FacebookAuthProvider.credential(
                withAccessToken: accessTokenString
            )
            
            Auth.auth().signIn(with: credential) { (result, error) in
                if let user = result?.user {
                    completion()
                }
                
                // TODO: Handle error
            }
        }
    }
}

