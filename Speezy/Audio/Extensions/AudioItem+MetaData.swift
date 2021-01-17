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
            date: lastUpdated,
            tags: tags,
            remoteUrl: remoteUrl,
            attachmentUrl: attachmentUrl,
            duration: duration
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
            date: lastUpdated,
            tags: tags + tags,
            remoteUrl: remoteUrl,
            attachmentUrl: attachmentUrl,
            duration: duration
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
            date: lastUpdated,
            tags: newTags,
            remoteUrl: remoteUrl,
            attachmentUrl: attachmentUrl,
            duration: duration
        )
        
        return newItem
    }
    
    func withStagingPath() -> AudioItem {
        withPath(path: "\(id)_staging.\(AudioConstants.fileExtension)")
    }
    
    func withPath(path: String) -> AudioItem {
        AudioItem(
            id: id,
            path: path,
            title: title,
            date: lastUpdated,
            tags: tags,
            remoteUrl: remoteUrl,
            attachmentUrl: attachmentUrl,
            duration: duration
        )
    }
    
    func withRemoteUrl(_ url: URL) -> AudioItem {
        AudioItem(
            id: id,
            path: path,
            title: title,
            date: lastUpdated,
            tags: tags,
            remoteUrl: url,
            attachmentUrl: attachmentUrl,
            duration: duration
        )
    }
    
    func withAttachmentUrl(_ url: URL?) -> AudioItem {
        AudioItem(
            id: id,
            path: path,
            title: title,
            date: lastUpdated,
            tags: tags,
            remoteUrl: remoteUrl,
            attachmentUrl: url,
            duration: duration
        )
    }
}
