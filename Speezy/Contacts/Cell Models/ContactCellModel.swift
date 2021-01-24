//
//  ContactCellModel.swift
//  Speezy
//
//  Created by Matt Beaney on 23/01/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import UIKit
import FirebaseStorage

class ContactCellModel {
    private var downloadTask: StorageDownloadTask?
    
    let contact: Contact
    let selected: Bool?
    
    init(contact: Contact, selected: Bool?) {
        self.contact = contact
        self.selected = selected
    }
}

extension ContactCellModel {
    var titleText: String {
        contact.displayName
    }
    
    var userNameText: String {
        "(\(contact.userName))"
    }
    
    func tickImage(for selected: Bool?) -> UIImage? {
        guard let selected = selected else {
            return nil
        }
        
        return selected ? UIImage(named: "ticked-contact") : UIImage(named: "unticked-contact")
    }
    
    func loadImage(completion: @escaping (StorageFetchResult<UIImage>) -> Void) {
        if contact.profilePhotoUrl == nil {
            // TODO: Handle image error better here.
            let error = NSError(domain: "", code: 404, userInfo: nil)
            completion(.failure(error))
            return
        }
        
        downloadTask?.cancel()
        downloadTask = CloudImageManager.fetchImage(
            at: "users/\(contact.userId).jpg",
            completion: completion
        )
    }
}

