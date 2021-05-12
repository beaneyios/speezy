//
//  String+DecimalRemoval.swift
//  Speezy
//
//  Created by Matt Beaney on 10/05/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation

extension String {
    func isSmallerThan(_ otherVersion: String) -> Bool {
        versionCompare(otherVersion) == .orderedAscending
    }
    
    func versionCompare(_ otherVersion: String) -> ComparisonResult {
        return self.compare(otherVersion, options: .numeric)
    }
}
