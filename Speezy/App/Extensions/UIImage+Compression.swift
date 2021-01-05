//
//  UIImage+Compression.swift
//  Speezy
//
//  Created by Matt Beaney on 04/01/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import UIKit

extension UIImage {
    // MARK: - UIImage+Resize
    func compress(to expectedSizeInMb: Double) -> Data? {
        let sizeInBytes = expectedSizeInMb * 1024 * 1024
        
        var needCompress = true
        var imgData: Data?
        var compressingValue: CGFloat = 1.0
        while (needCompress) {
            if compressingValue <= 0.0 {
                needCompress = false
                continue
            }
            
            if let data = jpegData(compressionQuality: compressingValue) {
                imgData = data
                
                if data.count < Int(sizeInBytes) {
                    needCompress = false
                } else {
                    compressingValue -= 0.1
                }
            }
        }

        if let data = imgData {
            return data
        }
        
        return nil
    }
}

