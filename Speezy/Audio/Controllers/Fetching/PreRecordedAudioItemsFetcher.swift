//
//  PreRecordedFetcher.swift
//  Speezy
//
//  Created by Matt Beaney on 06/06/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation

class PreRecordedAudioItemsFetcher: AudioItemsFetcher {
    override init(kind: Kind = .preRecorded) {
        super.init(kind: kind)
    }
    
    override func itemsPath(userId: String) -> String {
        "shared_audio"
    }
}
