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
    let date: Date
    let tags: [Tag]
    
    var attachmentUrl: URL?
    var remoteUrl: URL?
    
    var fileUrl: URL {
        FileManager.default.documentsURL(with: path)!
    }
    
    var duration: TimeInterval {
        TimeInterval(CMTimeGetSeconds(AVAsset(url: fileUrl).duration))
    }
    
    init(
        id: String,
        path: String,
        title: String,
        date: Date,
        tags: [Tag],
        remoteUrl: URL? = nil,
        attachmentUrl: URL? = nil
    ) {
        self.id = id
        self.path = path
        self.title = title
        self.date = date
        self.tags = tags
        self.remoteUrl = remoteUrl
    }
}
