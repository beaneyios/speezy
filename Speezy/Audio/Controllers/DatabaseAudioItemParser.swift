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
        return AudioItem.fromDict(key: key, dict: dict)
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
