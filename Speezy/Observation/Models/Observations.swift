//
//  Observations.swift
//  Speezy
//
//  Created by Matt Beaney on 14/11/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import Foundation

struct AudioPlayerObservation {
    weak var observer: AudioPlayerObserver?
}

struct AudioRecorderObservation {
    weak var observer: AudioRecorderObserver?
}

struct AudioCropperObservation {
    weak var observer: AudioCropperObserver?
}

struct TranscriptionJobObservation {
    weak var observer: TranscriptionJobObserver?
}

struct TranscriptObservation {
    weak var observer: TranscriptObserver?
}
