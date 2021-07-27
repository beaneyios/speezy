//
//  AudioItem.swift
//  Speezy
//
//  Created by Matt Beaney on 14/07/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import Foundation
import AVKit

struct Tag: Codable, Equatable, Identifiable, Hashable {
    let id: String
    let title: String
}

struct AudioItem: Codable, Equatable, Identifiable, Hashable {
    let id: String
    let title: String
    let path: String
    let lastUpdated: Date
    let tags: [Tag]
    let duration: TimeInterval
    
    let attachedMessageIds: [String]
    
    var attachmentUrl: URL?
    var remoteUrl: URL?
    
    var calculatedDuration: TimeInterval {
        TimeInterval(CMTimeGetSeconds(AVAsset(url: fileUrl).duration))
    }
    
    var fileUrl: URL {
        FileManager.default.documentsURL(with: path)!
    }
    
    var existsLocally: Bool {
        fileUrl.data != nil
    }
    
    init(
        id: String,
        path: String,
        title: String,
        date: Date,
        tags: [Tag],
        remoteUrl: URL? = nil,
        attachmentUrl: URL? = nil,
        duration: TimeInterval = 0.0,
        attachedMessageIds: [String] = []
    ) {
        self.id = id
        self.path = path
        self.title = title
        self.lastUpdated = date
        self.tags = tags
        self.remoteUrl = remoteUrl
        self.duration = duration
        self.attachmentUrl = attachmentUrl
        self.attachedMessageIds = attachedMessageIds
    }
}

extension AudioItem {
    var toDict: [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "duration": calculatedDuration,
            "title": title,
            "last_updated": lastUpdated.timeIntervalSince1970,
            "last_updated_sort": -lastUpdated.timeIntervalSince1970
        ]
        
        if let url = remoteUrl {
            dict["url"] = url.absoluteString
        }
        
        return dict
    }
    
    static func fromDict(key: String, dict: NSDictionary) -> AudioItem? {
        guard
            let duration = dict["duration"] as? TimeInterval,
            let title = dict["title"] as? String,
            let urlString = dict["url"] as? String,
            let url = URL(string: urlString),
            let timestamp = dict["last_updated"] as? TimeInterval
        else {
            return nil
        }
        
        return AudioItem(
            id: key,
            path: "\(key).m4a",
            title: title,
            date: Date(timeIntervalSince1970: timestamp),
            tags: [],
            remoteUrl: url,
            attachmentUrl: self.attachmentUrl(from: dict),
            duration: duration,
            attachedMessageIds: self.attachedMessageIds(from: dict["occurrences"] as? String)
        )
    }
    
    private static func attachmentUrl(from dict: NSDictionary) -> URL? {
        guard
            let attachmentString = dict["attachment_url"] as? String,
            let attachmentUrl = URL(string: attachmentString)
        else {
            return nil
        }
        
        return attachmentUrl
    }
    
    private static func attachedMessageIds(from occurrences: String?) -> [String] {
        guard let occurrences = occurrences else {
            return []
        }
        
        return occurrences.components(separatedBy: ",")
    }
}
