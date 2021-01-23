//
//  String+RelativeTime.swift
//  Speezy
//
//  Created by Matt Beaney on 23/01/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation
import AFDateHelper

extension Date {
    var relativeTimeString: String {
        let hoursString = toString(format: DateFormatType.custom("HH:mm"))
        let monthString = toString(format: DateFormatType.custom("EEE dd MMM"))
        let yearString = toString(format: DateFormatType.custom("EEE dd MMM yyyy"))
        
        return toStringWithRelativeTime(
            strings: [
                RelativeTimeStringType.nowPast: "Just now",
                RelativeTimeStringType.secondsPast: "Just now",
                RelativeTimeStringType.minutesPast: hoursString,
                RelativeTimeStringType.hoursPast: hoursString,
                RelativeTimeStringType.daysPast: monthString,
                RelativeTimeStringType.monthsPast: monthString,
                RelativeTimeStringType.yearsPast: yearString
            ]
        )
    }
}
