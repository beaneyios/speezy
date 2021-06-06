//
//  InserterObservationManaging.swift
//  Speezy
//
//  Created by Matt Beaney on 02/06/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation

protocol InserterObservationManaging: AnyObject {
    var inserterObservations: [ObjectIdentifier : AudioInserterObservation] { get set }
}

extension InserterObservationManaging {
    func addInserterObserver(_ observer: AudioInserterObserver) {
        let id = ObjectIdentifier(observer)
        inserterObservations[id] = AudioInserterObservation(observer: observer)
    }
    
    func removeCutterObserver(_ observer: AudioInserterObserver) {
        let id = ObjectIdentifier(observer)
        inserterObservations.removeValue(forKey: id)
    }
}
