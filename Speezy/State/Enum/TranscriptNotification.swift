//
//  TranscriptNotification.swift
//  Speezy
//
//  Created by Matt Beaney on 14/11/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import Foundation

enum TranscriptAction {
    case finishedEditingTranscript(
            transcript: Transcript,
            audioId: String
         )
}
