//
//  Chatter.swift
//  Speezy
//
//  Created by Matt Beaney on 18/01/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import UIKit

struct Chatter: Equatable {
    let id: String
    let displayName: String
    let profileImageUrl: URL?
}

extension Array where Element == Chatter {
    func chatter(for id: String) -> Chatter? {
        first { $0.id == id }
    }
}
