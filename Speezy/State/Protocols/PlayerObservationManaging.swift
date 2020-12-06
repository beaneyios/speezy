//
//  ObservationManaging.swift
//  Speezy
//
//  Created by Matt Beaney on 14/11/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import Foundation

protocol PlayerObservationManaging: AnyObject {
    var playerObservatons: [ObjectIdentifier : AudioPlayerObservation] { get set }
}

extension PlayerObservationManaging {
    func addPlaybackObserver(_ observer: AudioPlayerObserver) {
        let id = ObjectIdentifier(observer)
        playerObservatons[id] = AudioPlayerObservation(observer: observer)
    }
    
    func removePlaybackObserver(_ observer: AudioPlayerObserver) {
        let id = ObjectIdentifier(observer)
        playerObservatons.removeValue(forKey: id)
    }
}
