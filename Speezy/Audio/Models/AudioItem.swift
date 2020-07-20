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
    let path: String
    
    var url: URL {
        FileManager.default.documentsURL(with: path)!
    }
    
    init(id: String, path: String) {
        self.id = id
        self.path = path
    }
}
