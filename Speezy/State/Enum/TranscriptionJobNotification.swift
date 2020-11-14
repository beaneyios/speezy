//
//  TranscriptionJobNotification.swift
//  Speezy
//
//  Created by Matt Beaney on 14/11/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import Foundation

enum TranscriptionJobAction {
    case transcriptionComplete(transcript: Transcript, audioId: String)
    case transcriptionQueued(audioId: String)
}
