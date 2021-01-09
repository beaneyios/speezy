//
//  Previews.swift
//  SpeezyWidgetExtension
//
//  Created by Stephen Hofmeyr on 09/01/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import WidgetKit
import SwiftUI
import Intents

struct SpeezyWidget_Previews: PreviewProvider {
    static var previews: some View {
        SpeezyWidgetEntryView(entry: SimpleEntry(date: Date(), configuration: ConfigurationIntent()))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
