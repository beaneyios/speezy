//
//  SignOutManager.swift
//  Speezy
//
//  Created by Matt Beaney on 30/03/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation
import FirebaseAuth
import FBSDKLoginKit

class SignOutManager {
    static var shared: SignOutManager = SignOutManager()
    
    private var store: Store!
    private var auth: Auth!
    private var loginManager: LoginManager!
    private var pushSyncService: PushTokenSyncService!
    
    func configure(
        auth: Auth,
        loginManager: LoginManager,
        pushSyncService: PushTokenSyncService,
        store: Store
    ) {
        self.store = store
        self.auth = auth
        self.loginManager = loginManager
        self.pushSyncService = pushSyncService
    }
    
    func signOut() {
        pushSyncService.unsyncPushToken()
        store.userDidLogOut()
        
        try? auth.signOut()
        loginManager.logOut()
    }
}
