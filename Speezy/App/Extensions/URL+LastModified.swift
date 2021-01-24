//
//  URL+LastModified.swift
//  Speezy
//
//  Created by Matt Beaney on 17/01/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation

extension URL {
    var lastModified: Date? {
        do {
            return try resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate
        } catch let error as NSError {
            print("\(#function) Error: \(error)")
            return nil
        }
    }
}
