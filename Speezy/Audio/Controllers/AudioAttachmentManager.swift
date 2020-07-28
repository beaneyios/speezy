//
//  AudioAttachmentManager.swift
//  Speezy
//
//  Created by Matt Beaney on 27/07/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import Foundation
import UIKit

class AudioAttachmentManager {
    private(set) var imageAttachmentCache = [String: UIImage]()
    
    func resetCache() {
        imageAttachmentCache = [:]
    }
    
    func storeAttachment(
        _ image: UIImage?,
        forItem item: AudioItem,
        completion: @escaping () -> Void
    ) {
        if let image = image {
            imageAttachmentCache[item.id] = image
        } else {
            imageAttachmentCache.removeValue(forKey: item.id)
        }
        
        DispatchQueue.global().async {
            guard
                let url = FileManager.default.documentsURL(with: "\(item.id).dat")
            else {
                return
            }
            
            guard let imageData = image?.jpegData(compressionQuality: 1.0) else {
                FileManager.default.deleteExistingURL(url)
                completion()
                return
            }
                        
            try? imageData.write(to: url)
            completion()
        }
    }
    
    func fetchAttachment(
        forItem item: AudioItem,
        completion: @escaping (UIImage?) -> Void
    ) {
        if let attachment = imageAttachmentCache[item.id] {
            completion(attachment)
            return
        }
        
        DispatchQueue.global().async {
            guard let url = FileManager.default.documentsURL(with: "\(item.id).dat") else {
                completion(nil)
                return
            }
            
            guard let data = try? Data(contentsOf: url) else {
                completion(nil)
                return
            }
            
            DispatchQueue.main.async {
                let image = UIImage(data: data)
                if let image = image {
                    self.imageAttachmentCache[item.id] = image
                }
                
                completion(image)
            }
        }
    }
}
