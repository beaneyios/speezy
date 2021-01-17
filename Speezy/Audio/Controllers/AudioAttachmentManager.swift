//
//  AudioAttachmentManager.swift
//  Speezy
//
//  Created by Matt Beaney on 27/07/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import Foundation
import UIKit

enum AttachmentChangeResult {
    case success(AudioItem)
    case failure(Error?)
}

enum AttachmentFetchResult {
    case success(UIImage)
    case failure(Error?)
}

typealias AttachmentChangeHandler = (AttachmentChangeResult) -> Void
typealias AttachmentFetchHandler = (Result<UIImage, Error>) -> Void

class AudioAttachmentManager {

    private(set) var imageAttachmentCache = [String: UIImage]()
    
    private func cloudPath(forId id: String) -> String {
        "attachments/\(id).jpg"
    }
    
    func resetCache() {
        imageAttachmentCache = [:]
    }
    
    func storeAttachment(
        _ image: UIImage,
        forItem item: AudioItem,
        completion: AttachmentChangeHandler? = nil
    ) {
        imageAttachmentCache[item.id] = image
        
        CloudImageManager.uploadImage(
            image,
            path: cloudPath(forId: item.id)
        ) { (result) in
            switch result {
            case let .success(url):
                completion?(.success(item.withAttachmentUrl(url)))
            case let .failure(error):
                completion?(.failure(error))
            }
        }
    }
    
    func removeAttachment(
        forItem item: AudioItem,
        completion: AttachmentChangeHandler? = nil
    ) {
        if imageAttachmentCache[item.id] == nil {
            completion?(.success(item))
            return
        }
        
        imageAttachmentCache[item.id] = nil
        
        CloudImageManager.deleteImage(
            at: cloudPath(forId: item.id)
        ) { (result) in
            switch result {
            case .success:
                completion?(.success(item.withAttachmentUrl(nil)))
            case let .failure(error):
                completion?(.failure(error))
            }
        }
    }
    
    func fetchAttachment(
        forItem item: AudioItem,
        completion: @escaping AttachmentFetchHandler
    ) {
        if let attachment = imageAttachmentCache[item.id] {
            completion(.success(attachment))
            return
        }
        
        CloudImageManager.fetchImage(at: cloudPath(forId: item.id)) { (result) in
            switch result {
            case let .success(image):
                completion(.success(image))
            case let .failure(error):                
                completion(.failure(error))
            }
        }
    }
}
