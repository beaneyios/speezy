//
//  SimpleEntry.swift
//  SpeezyWidgetExtension
//
//  Created by Matt Beaney on 08/01/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import WidgetKit
import SwiftUI
import Intents

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationIntent
}
