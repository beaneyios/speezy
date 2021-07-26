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
    let commentsStore = CommentsStore()
    
    func userDidLogOut() {
        chatStore.clear()
        contactStore.clear()
        myRecordingsStore.clear()
        favouritesStore.clear()
        profileStore.clear()
        messagesStore.clear()        
    }
    
    func startListeningForCoreChanges(userId: String) {
        chatStore.listenForChats(userId: userId)
        contactStore.listenForContacts(userId: userId)
        profileStore.fetchProfile(userId: userId)
    }
}
