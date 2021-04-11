//
//  UserStore.swift
//  Speezy
//
//  Created by Matt Beaney on 13/02/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation

class ProfileStore {
    private let profileListener = ProfileListener()
    private let profileFetcher = ProfileFetcher()
    private let tokenService = PushTokenSyncService()
    
    private(set) var profile: Profile?
    
    private var observations = [ObjectIdentifier : ProfileObservation]()
    private let serialQueue = DispatchQueue(label: "com.speezy.profileStoreActions")
    
    func clear() {
        self.profileListener.stopListening()
        self.profile = nil
        self.observations = [:]
    }
    
    func setProfile(profile: Profile) {
        serialQueue.async {
            self.notifyObservers(change: .initialProfileReceived(profile))
        }        
    }
    
    func fetchProfile(userId: String) {
        profileFetcher.fetchProfile(userId: userId) { (result) in
            self.serialQueue.async {
                switch result {
                case let .success(profile):
                    self.profile = profile
                    self.notifyObservers(change: .initialProfileReceived(profile))
                    self.listenForProfile(userId: userId)
                    self.syncPushToken(token: profile.pushToken)
                case let .failure(error):
                    break
                }
            }
        }
    }
    
    private func syncPushToken(token: String?) {
        tokenService.syncRemotePushToken(token)
    }
    
    private func listenForProfile(userId: String) {
        profileListener.didChange = { change in
            self.serialQueue.async {
                switch change {
                case let .profileUpdated(change):
                    self.handleProfileUpdated(change: change)
                }
            }
        }
        
        profileListener.listenForProfileChanges(userId: userId)
    }
    
    private func handleProfileUpdated(change: ProfileValueChange) {
        // Apply the change.
        let newProfile: Profile? = {
            guard var updatedProfile = self.profile else {
                return nil
            }
            
            switch change.profileValue {
            case let .name(name):
                updatedProfile.name = name
            case let .userName(username):
                updatedProfile.userName = username
            case let .occupation(occupation):
                updatedProfile.occupation = occupation
            case let .aboutYou(aboutYou):
                updatedProfile.aboutYou = aboutYou
            case let .profileImageUrl(url):
                updatedProfile.profileImageUrl = url
            case let .pushToken(pushToken):
                updatedProfile.pushToken = pushToken
            }
            
            return updatedProfile
        }()
        
        // Replace the old chat with the new one.
        if let newProfile = newProfile {
            self.profile = newProfile
            notifyObservers(change: .profileUpdated(newProfile))
        }
    }
}

extension ProfileStore {
    enum Change {
        case initialProfileReceived(Profile)
        case profileUpdated(Profile)
    }
    
    func addProfileObserver(_ observer: ProfileObserver) {
        serialQueue.async {
            let id = ObjectIdentifier(observer)
            self.observations[id] = ProfileObservation(observer: observer)
            
            if let profile = self.profile {
                // We might be mid-load, let's give the new subscriber what we have so far.
                observer.initialProfileReceived(profile: profile)
            }
        }
    }
    
    func removeProfileObserver(_ observer: ProfileObserver) {
        serialQueue.async {
            let id = ObjectIdentifier(observer)
            self.observations.removeValue(forKey: id)
        }
    }
    
    private func notifyObservers(change: Change) {
        observations.forEach {
            guard let observer = $0.value.observer else {
                observations.removeValue(forKey: $0.key)
                return
            }
            
            switch change {
                
            case let .initialProfileReceived(profile):
                observer.initialProfileReceived(profile: profile)
            case let .profileUpdated(profile):
                observer.profileUpdated(profile: profile)
            }
        }
    }
}
