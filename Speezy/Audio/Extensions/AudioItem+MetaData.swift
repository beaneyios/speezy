//
//  AudioItem+MetaData.swift
//  Speezy
//
//  Created by Matt Beaney on 14/11/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import Foundation

extension AudioItem {
    func withUpdatedTitle(_ title: String) -> AudioItem {
        let newItem = AudioItem(
            id: id,
            path: path,
            title: title,
            date: date,
            tags: tags
        )
        
        return newItem
    }
    
    func addingTag(withTitle title: String) -> AudioItem {
        
        let tagTitles = title.split(separator: ",")
        
        let tags = tagTitles.map {
            Tag(id: UUID().uuidString, title: String($0))
        }
                
        let newItem = AudioItem(
            id: id,
            path: path,
            title: title,
            date: date,
            tags: tags + tags
        )
        
        return newItem
    }
    
    func removingTag(tag: Tag) -> AudioItem {
        let newTags = tags.filter {
            $0.id != tag.id
        }
        
        let newItem = AudioItem(
            id: id,
            path: path,
            title: title,
            date: date,
            tags: newTags
        )
        
        return newItem
    }
    
    func withStagingPath() -> AudioItem {
        withPath(path: "\(id)_staging.wav")
    }
    
    func withPath(path: String) -> AudioItem {
        AudioItem(
            id: id,
            path: path,
            title: title,
            date: date,
            tags: tags
        )
    }
}
