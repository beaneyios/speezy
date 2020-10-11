//
//  Transcript.swift
//  Speezy
//
//  Created by Matt Beaney on 13/09/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import Foundation

struct Timestamp: Codable, Equatable {
    let start: TimeInterval
    let end: TimeInterval
}

struct Word: Codable, Equatable {
    let text: String
    let timestamp: Timestamp
}

struct Transcript: Codable {
    let words: [Word]
}
