//
//  RecorderObservationManaging.swift
//  Speezy
//
//  Created by Matt Beaney on 14/11/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import Foundation

protocol RecorderObservationManaging: AnyObject {
    var recorderObservatons: [ObjectIdentifier : AudioRecorderObservation] { get set }
}

extension RecorderObservationManaging {
    func addRecorderObserver(_ observer: AudioRecorderObserver) {
        let id = ObjectIdentifier(observer)
        recorderObservatons[id] = AudioRecorderObservation(observer: observer)
    }
    
    func removeRecorderObserver(_ observer: AudioRecorderObserver) {
        let id = ObjectIdentifier(observer)
        recorderObservatons.removeValue(forKey: id)
    }
}
