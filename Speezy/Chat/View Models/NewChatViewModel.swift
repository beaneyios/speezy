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
        case loaded
        case chatCreated(Chat)
    }
    
    private(set) var selectedContacts = [Contact]()
    private(set) var title: String?
    private(set) var attachedImage: UIImage?
    
    private(set) var items = [ContactCellModel]()
    
    var didChange: ((Change) -> Void)?
    let contactListManager = DatabaseContactManager()
    let chatManager = DatabaseChatManager()
    let profileManager = DatabaseProfileManager()
    
    var shouldShowEmptyView: Bool {
        items.isEmpty
    }
    
    func listenForData() {
        guard let userId = Auth.auth().currentUser?.uid else {
            assertionFailure("No user id")
            return
        }
        
        contactListManager.fetchContacts(userId: userId) { (result) in
            switch result {
            case let .success(contacts):
                self.items = contacts.map {
                    ContactCellModel(contact: $0, selected: self.selectedContacts.contains($0))
                }
                
                self.didChange?(.loaded)
            case let .failure(error):
                break
            }
        }
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
    }
    
    func createChat() {
        guard let userId = Auth.auth().currentUser?.uid else {
            assertionFailure("No user id")
            return
        }
        
        createChatInFirebase(userId: userId) { (result) in
            switch result {
            case let .success(chat):
                if let attachment = self.attachedImage {
                    self.uploadImageAndUpdate(image: attachment, chat: chat)
                } else {
                    self.didChange?(.chatCreated(chat))
                }
            case let .failure(error):
                break
            }
        }
    }
    
    private func uploadImageAndUpdate(image: UIImage, chat: Chat) {
        CloudImageManager.uploadImage(
            image,
            path: "chats/\(chat.id).jpg")
        { (result) in
            switch result {
            case let .success(url):
                let newChat = chat.withChatImageUrl(url)
                self.updateChatInFirebase(chat: newChat)
            case let .failure(error):
                self.didChange?(.chatCreated(chat))
            }
        }
    }
    
    private func updateChatInFirebase(chat: Chat) {
        chatManager.updateChat(chat: chat) { (result) in
            switch result {
            case let .success(chat):
                self.didChange?(.chatCreated(chat))
            case let .failure(error):
                // TODO: Handle error
                break
            }
        }
    }
    
    private func createChatInFirebase(
        userId: String,
        completion: @escaping (Result<Chat, Error>) -> Void
    ) {
        profileManager.fetchProfile(userId: userId) { (result) in
            switch result {
            case let .success(profile):
                let chatter = Chatter(
                    id: userId,
                    displayName: profile.name,
                    profileImageUrl: profile.profileImageUrl,
                    pushToken: profile.pushToken
                )
                
                self.createChat(with: chatter, completion: completion)
            case let .failure(error):
                break
            }
        }
    }
    
    private func createChat(
        with chatter: Chatter,
        completion: @escaping (Result<Chat, Error>) -> Void
    ) {
        guard let title = self.title else {
            return
        }
        
        chatManager.createChat(
            title: title,
            currentChatter: chatter,
            contacts: selectedContacts
        ) { (result) in
            switch result {
            case let .success(chat):
                completion(.success(chat))
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }
}

extension NewChatViewModel {
    func validationError() -> FormError? {
        if title == nil || title?.isEmpty == true {
            return FormError(
                message: "Please choose a title",
                field: .chatTitle
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
