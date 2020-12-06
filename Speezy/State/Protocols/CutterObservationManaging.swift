//
//  CutterObservationManaging.swift
//  Speezy
//
//  Created by Matt Beaney on 22/11/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import Foundation

protocol CutterObservationManaging: AnyObject {
    var cutterObservations: [ObjectIdentifier : AudioCutterObservation] { get set }
}

extension CutterObservationManaging {
    func addCutterObserver(_ observer: AudioCutterObserver) {
        let id = ObjectIdentifier(observer)
        cutterObservations[id] = AudioCutterObservation(observer: observer)
    }
    
    func removeCutterObserver(_ observer: AudioCutterObserver) {
        let id = ObjectIdentifier(observer)
        cutterObservations.removeValue(forKey: id)
    }
}
