//
//  AudioCropper.swift
//  Speezy
//
//  Created by Matt Beaney on 20/07/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import Foundation
import AVKit

protocol AudioCropperDelegate: AnyObject {
    func audioCropper(_ cropper: AudioCropper, didAdjustCroppedItem item: AudioItem)
    func audioCropper(_ cropper: AudioCropper, didApplyCroppedItem item: AudioItem)
    func audioCropper(_ cropper: AudioCropper, didCancelCropReturningToItem item: AudioItem)
}

class AudioCropper: AudioCropping {
    private let item: AudioItem
    private(set) var croppedItem: AudioItem?
    private var cutItem: AudioItem?
    
    let cropExtension = "_cropped.\(AudioConstants.audioFormatKey)"
    
    private(set) var cropFrom: TimeInterval?
    private(set) var cropTo: TimeInterval?
    
    weak var delegate: AudioCropperDelegate?
    
    init(item: AudioItem) {
        self.item = item
    }
    
    func crop(from: TimeInterval, to: TimeInterval) {
        cropFrom = from
        cropTo = to
        
        crop(audioItem: item, startTime: from, stopTime: to) { (path) in
            let croppedItem = self.item.withPath(path: path)
            self.croppedItem = croppedItem
            self.delegate?.audioCropper(self, didAdjustCroppedItem: croppedItem)
        }
    }
    
    func applyCrop() {
        guard let croppedItem = self.croppedItem else {
            delegate?.audioCropper(self, didCancelCropReturningToItem: item)
            return
        }
        
        FileManager.default.deleteExistingFile(with: self.item.path)
        FileManager.default.renameFile(
            from: "\(item.id)\(cropExtension)",
            to: item.path
        )
        
        delegate?.audioCropper(self, didApplyCroppedItem: croppedItem)
    }
    
    func cancelCrop() {
        delegate?.audioCropper(self, didCancelCropReturningToItem: item)
    }
}
