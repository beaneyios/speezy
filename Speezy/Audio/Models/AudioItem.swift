//
//  AudioItem.swift
//  Speezy
//
//  Created by Matt Beaney on 14/07/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import Foundation

struct AudioItem: Codable, Equatable, Identifiable {
    let id: String
    let url: URL
    
    init(id: String, url: URL) {
        self.id = id
        self.url = url
    }
}
