//
//  AudioItem.swift
//  Speezy
//
//  Created by Matt Beaney on 14/07/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import Foundation
import AVKit

struct Tag: Codable, Equatable, Identifiable {
    let id: String
    let title: String
}

struct AudioItem: Codable, Equatable, Identifiable {
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
