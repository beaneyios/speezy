//
//  NewChatViewModel.swift
//  Speezy
//
//  Created by Matt Beaney on 23/01/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation
import FirebaseAuth

class NewChatViewModel {
    enum Change {
        case profileLoaded
        case loaded
        case chatCreated(Chat)
    }
    
    private let store: Store
    private(set) var selectedContacts = [Contact]()
    private(set) var title: String?
    private(set) var attachedImage: UIImage?
    
    private(set) var items = [ContactCellModel]()
    
    var didChange: ((Change) -> Void)?
    let contactListManager = DatabaseContactManager()
    let chatCreator = ChatCreator()
    
    private var profile: Profile?
    
    var shouldShowEmptyView: Bool {
        items.isEmpty
    }
    
    init(store: Store, contact: Contact?) {
        self.store = store
        
        if let contact = contact {
            self.selectedContacts.append(contact)
        }
    }
    
    func listenForData() {
        store.profileStore.addProfileObserver(self)
        store.contactStore.addContactListObserver(self)
    }
    
    func setImage(_ image: UIImage?) {
        self.attachedImage = image
    }
    
    func setTitle(_ title: String) {
        self.title = title
    }
    
    func selectContact(contact: Contact) {
        if let contactIndex = selectedContacts.firstIndex(of: contact) {
            selectedContacts.remove(at: contactIndex)
        } else {
            selectedContacts.append(contact)
        }
        
        self.items = items.map {
            let newItem = ContactCellModel(
                contact: $0.contact,
                selected: self.selectedContacts.contains($0.contact)
            )
            
            return newItem
        }
    }
    
    func createChat() {
        guard
            let profile = profile,
            let newChatId = chatCreator.newChatId()
        else {
            assertionFailure("No chat id")
            return
        }
        
        let currentChatter = Chatter(
            id: profile.userId,
            displayName: profile.name,
            profileImageUrl: profile.profileImageUrl,
            color: UIColor.random
        )
        
        if let attachment = self.attachedImage {
            self.uploadImageAndCreateChat(
                chatId: newChatId,
                title: title,
                currentChatter: currentChatter,
                contacts: selectedContacts,
                image: attachment
            )
        } else {
            self.createChat(
                chatId: newChatId,
                title: title,
                attachmentUrl: nil,
                chatter: currentChatter,
                contacts: selectedContacts
            )
        }
    }
    
    private func updateCellModels(contacts: [Contact]) {
        self.items = contacts.map {
            ContactCellModel(contact: $0, selected: self.selectedContacts.contains($0))
        }
        
        self.didChange?(.loaded)
    }
    
    private func uploadImageAndCreateChat(
        chatId: String,
        title: String?,
        currentChatter: Chatter,
        contacts: [Contact],
        image: UIImage
    ) {
        CloudImageManager.uploadImage(
            image,
            path: "chats/\(chatId).jpg")
        { (result) in
            switch result {
            case let .success(url):
                self.createChat(
                    chatId: chatId,
                    title: title,
                    attachmentUrl: url,
                    chatter: currentChatter,
                    contacts: contacts
                )
            case let .failure(error):
                break
            }
        }
    }
    
    private func createChat(
        chatId: String,
        title: String?,
        attachmentUrl: URL?,
        chatter: Chatter,
        contacts: [Contact]
    ) {        
        chatCreator.createChat(
            chatId: chatId,
            title: title,
            attachmentUrl: attachmentUrl,
            currentChatter: chatter,
            contacts: contacts
        ) { (result) in
            switch result {
            case let .success(chat):
                self.didChange?(.chatCreated(chat))
            case let .failure(error):
                break
            }
        }
    }
}

extension NewChatViewModel {
    func validationError() -> FormError? {
        if selectedContacts.count > 1 && title == nil {
            return FormError(
                message: "Please choose a group title",
                field: .chatTitle
            )
        }
        
        if selectedContacts.count > 10 {
            return FormError(
                message: "Chats can have a maximum of 10 people",
                field: nil
            )
        }
        
        if selectedContacts.isEmpty {
            return FormError(
                message: "Please select at least one contact",
                field: nil
            )
        }
        
        return nil
    }
}

extension NewChatViewModel: ContactListObserver {
    func initialContactsReceived(contacts: [Contact]) {
        updateCellModels(contacts: contacts)
    }
    
    func allContacts(contacts: [Contact]) {
        updateCellModels(contacts: contacts)
    }
    
    func contactAdded(contact: Contact, in contacts: [Contact]) {}
    func contactUpdated(contact: Contact, in contacts: [Contact]) {}
    func contactRemoved(contact: Contact, contacts: [Contact]) {}
}

extension NewChatViewModel: ProfileObserver {
    func initialProfileReceived(profile: Profile) {
        self.profile = profile
        self.didChange?(.profileLoaded)
    }
    
    func profileUpdated(profile: Profile) {
        self.profile = profile
    }
}
