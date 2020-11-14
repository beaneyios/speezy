//
//  TranscriptionJobObservationManaging.swift
//  Speezy
//
//  Created by Matt Beaney on 14/11/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import Foundation

protocol TranscriptionJobObservationManaging: AnyObject {
    var transcriptionJobObservations: [ObjectIdentifier : TranscriptionJobObservation] { get set }
}

extension TranscriptionJobObservationManaging {
    func addTranscriptionObserver(_ observer: TranscriptionJobObserver) {
        let id = ObjectIdentifier(observer)
        transcriptionJobObservations[id] = TranscriptionJobObservation(observer: observer)
    }
    
    func removeTranscriptionObserver(_ observer: TranscriptionJobObserver) {
        let id = ObjectIdentifier(observer)
        transcriptionJobObservations.removeValue(forKey: id)
    }
}
