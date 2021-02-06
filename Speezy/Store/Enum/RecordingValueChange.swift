//
//  RecordingValueChange.swift
//  Speezy
//
//  Created by Matt Beaney on 06/02/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation

struct RecordingValueChange {
    let recordingId: String
    let recordingValue: RecordingValue
}

enum RecordingValue {
    case duration(TimeInterval)
    case lastUpdated(TimeInterval)
    case title(String)
    
    init?(key: String, value: Any) {
        if key == "duration", let duration = value as? TimeInterval {
            self = .duration(duration)
        } else if key == "last_updated", let lastUpdated = value as? TimeInterval {
            self = .lastUpdated(lastUpdated)
        } else if key == "title", let title = value as? String {
            self = .title(title)
        } else {
            return nil
        }
    }
}
