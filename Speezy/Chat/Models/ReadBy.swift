//
//  ReadBy.swift
//  Speezy
//
//  Created by Matt Beaney on 21/02/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation

struct ReadBy: Identifiable, Equatable {
    var id: String
    var time: TimeInterval
    
    init?(string: String) {
        let components = string.components(separatedBy: "_")
        guard
            components.count == 2,
            let time = TimeInterval(components[1])
        else {
            return nil
        }
        
        let id = components[0]
        self.init(id: id, time: time)
    }
    
    init(id: String, time: TimeInterval) {
        self.id = id
        self.time = time
    }
    
    var toString: String {
        "\(id)_\(time)"
    }
}
