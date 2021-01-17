//
//  AudioItemListViewModel.swift
//  Speezy
//
//  Created by Matt Beaney on 05/01/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation
import FirebaseStorage
import FirebaseAuth
import FBSDKLoginKit

class AudioItemListViewModel {
    
    enum Change {
        case itemsLoaded
        case profileImageLoaded(UIImage)
        case userSignedOut
    }
    
    var didChange: ((Change) -> Void)?
    var audioItems: [AudioItem] = []
    
    private(set) var audioAttachmentManager = AudioAttachmentManager()
    
    var shouldShowEmptyView: Bool {
        audioItems.isEmpty
    }
    
    func loadItems() {
        AudioStorage.fetchItems { result in
            switch result {
            case let .success(items):
                self.audioItems = items
                self.didChange?(.itemsLoaded)
            case let .failure(error):
                // TODO: Handle error
                assertionFailure("Errored with error \(error.localizedDescription)")
            }
        }
    }
    
    func reloadItem(_ item: AudioItem) {
//        if audioItems.contains(item) {
//            audioItems = audioItems.replacing(item)
//        } else {
//            audioItems.append(item)
//        }
        
        audioAttachmentManager.resetCache()
        
        didChange?(.itemsLoaded)
    }
    
    func deleteItem(_ item: AudioItem) {
//        audioAttachmentManager.storeAttachment(
//            nil,
//            forItem: item
//        )
//
//        FileManager.default.deleteExistingURL(
//            item.withStagingPath().fileUrl
//        )
//        FileManager.default.deleteExistingURL(item.fileUrl)
//        AudioStorage.deleteItem(item)
//        audioItems = audioItems.removing(item)
//        didChange?(.itemsLoaded)
    }
}

extension AudioItemListViewModel {
    func loadProfileImage() {
        guard let currentUser = Auth.auth().currentUser else {
            return
        }
        
        CloudImageManager.fetchImage(at: "profile_images/\(currentUser.uid).jpg") { (result) in
            switch result {
            case let .success(image):
                self.didChange?(.profileImageLoaded(image))
            case let .failure:
                if let defaultImage = UIImage(named: "account-btn") {
                    self.didChange?(.profileImageLoaded(defaultImage))
                }
            }
        }
    }
    
    func signOut() {
        LoginManager().logOut()
        try? Auth.auth().signOut()
        didChange?(.userSignedOut)
    }
}

extension AudioItemListViewModel {
    var numberOfItems: Int {
        audioItems.count
    }
    
    func item(at indexPath: IndexPath) -> AudioItem {
        audioItems[indexPath.row]
    }
}

extension AudioItemListViewModel {
    var newItem: AudioItem {
        let id = UUID().uuidString
        return AudioItem(
            id: id,
            path: "\(id).\(AudioConstants.fileExtension)",
            title: "",
            date: Date(),
            tags: []
        )
    }
}
