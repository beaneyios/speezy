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
    func storeAttachment(
        _ image: UIImage?,
        forItem item: AudioItem,
        completion: @escaping () -> Void
    ) {
        DispatchQueue.global().async {
            guard
                let url = FileManager.default.documentsURL(with: "\(item.id).dat")
            else {
                return
            }
            
            guard let imageData = image?.pngData() else {
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
                completion(UIImage(data: data))
            }
        }
    }
}
