//
//  TranscriptionJob.swift
//  Speezy
//
//  Created by Matt Beaney on 08/10/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import Foundation

struct TranscriptionJob: Equatable, Codable, Identifiable {
    var id: String
    var fileName: String
}
