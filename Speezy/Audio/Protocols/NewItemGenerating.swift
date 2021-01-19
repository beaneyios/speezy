//
//  NewItemGenerating.swift
//  Speezy
//
//  Created by Matt Beaney on 19/01/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation

protocol NewItemGenerating {
    var newItem: AudioItem { get }
}

extension NewItemGenerating {
    var newItem: AudioItem {
        let id = UUID().uuidString
        return AudioItem(
            id: id,
            path: "\(id).\(AudioConstants.fileExtension)",
            title: "",
            date: Date(),
            tags: []
        )
    }
}
