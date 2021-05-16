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
    private(set) var downloadTask: StorageDownloadTask?
    
    let chatter: Chatter
    let isAdmin: Bool
    
    init(chatter: Chatter, isAdmin: Bool) {
        self.chatter = chatter
        self.isAdmin = isAdmin
    }
}

extension ChatterCellModel {
    var titleText: String {
        chatter.displayName
    }
    
    func loadImage(completion: @escaping (StorageFetchResult<UIImage>) -> Void) {
        downloadTask?.cancel()
        if chatter.profileImageUrl == nil {
            completion(.success(letterImage()))
            return
        }
        
        downloadTask = CloudImageManager.fetchImage(
            at: "profile_images/\(chatter.id).jpg"
        ) { (result) in
            switch result {
            case let .success(image):
                completion(.success(image))
            case .failure:
                break
            }
        }
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

