//
//  Data+Size.swift
//  Speezy
//
//  Created by Matt Beaney on 04/01/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation

extension Data {
    var mbSize: Int64 {
        let bcf = ByteCountFormatter()
        bcf.allowedUnits = [.useMB]
        bcf.countStyle = .file
        return Int64(count / 1000 / 1000)
    }
}
