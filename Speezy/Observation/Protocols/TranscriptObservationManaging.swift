//
//  TranscriptObservationManaging.swift
//  Speezy
//
//  Created by Matt Beaney on 14/11/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import Foundation

protocol TranscriptObservationManaging: AnyObject {
    var transcriptObservations: [ObjectIdentifier : TranscriptObservation] { get set }
}

extension TranscriptObservationManaging {
    func addTranscriptObserver(_ observer: TranscriptObserver) {
        let id = ObjectIdentifier(observer)
        transcriptObservations[id] = TranscriptObservation(observer: observer)
    }
    
    func removeTranscriptObserver(_ observer: TranscriptObserver) {
        let id = ObjectIdentifier(observer)
        transcriptObservations.removeValue(forKey: id)
    }

}
