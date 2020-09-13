//
//  Transcript.swift
//  Speezy
//
//  Created by Matt Beaney on 13/09/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import Foundation

struct Word {
    let text: String
    let timestamp: TimeInterval
}

struct Transcript {
    let words: [Word]
}
