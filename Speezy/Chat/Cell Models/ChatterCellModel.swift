//
//  ChatterCellModel.swift
//  Speezy
//
//  Created by Matt Beaney on 12/05/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation
import FirebaseStorage

class ChatterCellModel {
    private var downloadTask: StorageDownloadTask?
    
    let chatter: Chatter
    
    init(chatter: Chatter) {
        self.chatter = chatter
    }
}

extension ChatterCellModel {
    var titleText: String {
        chatter.displayName
    }
    
    func loadImage(completion: @escaping (StorageFetchResult<UIImage>) -> Void) {
        if chatter.profileImageUrl == nil {
            completion(.success(letterImage()))
            return
        }
        
        downloadTask?.cancel()
        downloadTask = CloudImageManager.fetchImage(
            at: "profile_images/\(chatter.id).jpg",
            completion: completion
        )
    }
    
    private func letterImage() -> UIImage {
        guard let character = chatter.displayName.first else {
            return UIImage(named: "account-btn")!
        }
        
        return SpeezyProfileViewGenerator.generateProfileImage(
            character: String(character),
            color: chatter.color
        )
    }
}

