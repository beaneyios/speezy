//
//  Debouncer.swift
//  Speezy
//
//  Created by Matt Beaney on 24/01/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation

class SearchDebouncer {
    private var interval: TimeInterval
    private var worker = DispatchWorkItem(block: {})
    
    init(seconds: TimeInterval) {
        self.interval = seconds
    }
    
    func cancel() {
        worker.cancel()
    }
    
    func debounce(action: @escaping (() -> Void)) {
        worker.cancel()
        worker = DispatchWorkItem(block: { action() })
        DispatchQueue.main.asyncAfter(
            deadline: .now() + interval,
            execute: worker
        )
    }
}
