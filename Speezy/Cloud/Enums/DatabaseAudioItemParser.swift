//
//  DatabaseAudioItemParser.swift
//  Speezy
//
//  Created by Matt Beaney on 17/01/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation

class DatabaseAudioItemParser {
    static func parseItem(key: String, dict: NSDictionary) -> AudioItem? {
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
            duration: duration
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
}
