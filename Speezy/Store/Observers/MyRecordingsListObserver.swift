//
//  AudioItemListObserver.swift
//  Speezy
//
//  Created by Matt Beaney on 06/02/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation

protocol MyRecordingsListObserver: AnyObject {
    func recordingAdded(recording: AudioItem, recordings: [AudioItem])
    func recordingUpdated(recording: AudioItem, recordings: [AudioItem])
    func pagedRecordingsReceived(newRecordings: [AudioItem], recordings: [AudioItem])
    func recordingRemoved(recording: AudioItem, recordings: [AudioItem])
}
