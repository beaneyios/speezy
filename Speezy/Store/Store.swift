//
//  StoreController.swift
//  Speezy
//
//  Created by Matt Beaney on 30/01/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation

class Store {
    static let shared = Store()
    
    let chatStore = ChatStore()
    let contactStore = ContactStore()
    let myRecordingsStore = MyRecordingsStore()
    let favouritesStore = FavouriteRecordingsStore()
    let profileStore = ProfileStore()
    let messagesStore = MessagesStore()
    
    func userDidLogOut() {
        profileStore.clear()
        chatStore.clear()
        contactStore.clear()
    }
    
    func startListeningForCoreChanges(userId: String) {
        chatStore.listenForChats(userId: userId)
        contactStore.listenForContacts(userId: userId)
        profileStore.fetchProfile(userId: userId)
    }
}
