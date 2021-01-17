//
//  URL+ConvenienceInit.swift
//  Speezy
//
//  Created by Matt Beaney on 17/01/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation

extension URL {
    init?(key: String, dict: NSDictionary) {
        if let urlString = dict[key] as? String, let url = URL(string: urlString) {
            self = url
        } else {
            return nil
        }
    }
}
