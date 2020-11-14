//
//  CropperObservationManager.swift
//  Speezy
//
//  Created by Matt Beaney on 14/11/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import Foundation

protocol CropperObservationManaging: AnyObject {
    var cropperObservatons: [ObjectIdentifier : AudioCropperObservation] { get set }
}

extension CropperObservationManaging {
    func addCropperObserver(_ observer: AudioCropperObserver) {
        let id = ObjectIdentifier(observer)
        cropperObservatons[id] = AudioCropperObservation(observer: observer)
    }
    
    func removeCropperObserver(_ observer: AudioCropperObserver) {
        let id = ObjectIdentifier(observer)
        cropperObservatons.removeValue(forKey: id)
    }
}
