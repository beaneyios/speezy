//
//  Post.swift
//  Speezy
//
//  Created by Matt Beaney on 11/07/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation

struct Post: Hashable {
    var id: String
    var poster: Poster
    var item: AudioItem
}
