//
//  TranscriptStorage.swift
//  Speezy
//
//  Created by Matt Beaney on 27/10/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import Foundation

class TranscriptStorage {
    static func save(_ transcript: Transcript, id: String) {
        Storage.store(transcript, to: .documents, as: "\(id)_transcript")
    }
    
    static func deleteItem(_ transcript: Transcript, id: String) {
        if Storage.fileExists(id, in: .documents) {
            Storage.remove("\(id)_transcript", from: .documents)
        }
    }
    
    static func fetchTranscript(id: String) -> Transcript? {
        Storage.retrieve("\(id)_transcript", from: .documents, as: Transcript.self)
    }
    
    static func url(for id: String) -> URL {
        FileManager.default.documentsURL(with: id)!
    }
}
