//
//  AudioItemListViewModel.swift
//  Speezy
//
//  Created by Matt Beaney on 05/01/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation
import FirebaseAuth
import FBSDKLoginKit

class AudioItemListViewModel: NewItemGenerating {
    
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
        DatabaseAudioManager.fetchItems { (result) in
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
        if audioItems.contains(item) {
            audioItems = audioItems.replacing(item)
        } else {
            audioItems.append(item)
        }
        
        audioAttachmentManager.resetCache()
        didChange?(.itemsLoaded)
    }
    
    func deleteItem(_ item: AudioItem) {
        audioAttachmentManager.removeAttachment(forItem: item)

        AudioSavingManager().deleteItem(item) { (result) in
            switch result {
            case .success:
                self.audioItems = self.audioItems.removing(item)
                self.didChange?(.itemsLoaded)
            case let .failure(error):
                // TODO: Handle error
                assertionFailure("Deletion failed with error \(error.localizedDescription)")
                break
            }
        }
    }
}

extension AudioItemListViewModel {
    func loadProfileImage() {
        guard let currentUser = Auth.auth().currentUser else {
            return
        }
        
        // TODO: Only make this request when we know the profile has a link.
        CloudImageManager.fetchImage(at: "profile_images/\(currentUser.uid).jpg") { (result) in
            switch result {
            case let .success(image):
                break
//                self.didChange?(.profileImageLoaded(image))
            case .failure:
                break
//                if let defaultImage = UIImage(named: "account-btn") {
//                    self.didChange?(.profileImageLoaded(defaultImage))
//                }
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
