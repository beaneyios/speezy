//
//  TranscriptionJobStorage.swift
//  Speezy
//
//  Created by Matt Beaney on 08/10/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import Foundation

class TranscriptionJobStorage {
    private static let key = "transcription_jobs"
    
    static func save(_ job: TranscriptionJob) {
        var itemList = Storage.retrieve(
            key,
            from: .documents,
            as: [TranscriptionJob].self
            ) ?? []
        
        if itemList.contains(job) {
            itemList = itemList.replacing(job)
        } else {
            itemList.append(job)
        }
        
        Storage.store(itemList, to: .documents, as: key)
    }
    
    static func deleteItem(_ item: TranscriptionJob) {
        var itemList = Storage.retrieve(
            key,
            from: .documents,
            as: [TranscriptionJob].self
            ) ?? []
        
        itemList = itemList.removing(item)
        Storage.store(itemList, to: .documents, as: key)
    }
    
    static func fetchItems() -> [TranscriptionJob] {
        Storage.retrieve(key, from: .documents, as: [TranscriptionJob].self) ?? []
    }
    
    static func url(for id: String) -> URL {
        FileManager.default.documentsURL(with: id)!
    }
}
