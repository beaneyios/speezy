//
//  ChatItem.swift
//  Speezy
//
//  Created by Matt Beaney on 11/01/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import UIKit
import AFDateHelper

struct MessageCellModel {
    let message: Message
    let chat: Chat
    let currentUserId: String
    
    init(
        message: Message,
        chat: Chat,
        currentUserId: String
    ) {
        self.message = message
        self.chat = chat
        self.currentUserId = currentUserId
    }
}

extension MessageCellModel {
    var isSender: Bool {
        message.chatter.id == currentUserId
    }
    
    var received: Bool? {
        isSender ? message.readBy == chat.chatters : nil
    }
}

extension MessageCellModel {
    // Duration
    var durationText: String? {
        guard let duration = message.duration else {
            return nil
        }
        
        return duration.formattedString
    }
    
    var durationTint: UIColor {
        .white
    }
    
    // User info
    var profileImage: UIImage? {
        message.chatter.profileImage
    }
    
    var displayNameText: String {
        message.chatter.displayName
    }
    
    // Timestamp
    var timestampText: String {
        let hoursString = message.sent.toString(format: DateFormatType.custom("HH:mm"))
        let monthString = message.sent.toString(format: DateFormatType.custom("EEE dd MMM"))
        let yearString = message.sent.toString(format: DateFormatType.custom("EEE dd MMM yyyy"))
        return message.sent.toStringWithRelativeTime(
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
    
    var timestampTint: UIColor {
        isSender ? .white : .darkGray
    }
    
    var playButtonTint: UIColor {
        isSender ? .white : .speezyPurple
    }
    
    // Message
    var messageText: String? {
        message.message
    }
    
    var messageTint: UIColor {
        isSender ? .white : .black
    }
    
    //Background
    var backgroundImage: UIImage? {
        isSender ? UIImage(named: "gradient-background") : nil
    }
    
    // Ticks
    var tickTint: UIColor? {
        guard let received = self.received else {
            return nil
        }
        
        let receivedTint = UIColor.speezyPurple
        let notReceivedTint = UIColor.speezyDarkGrey
        return received ? receivedTint : notReceivedTint
    }
    
    var tickOpacity: CGFloat {
        guard let received = received else {
            return 0.0
        }

        return received ? 1.0 : 0.6
    }
    
    var tickWidth: CGFloat {
        isSender ? 15.0 : 0.0
    }
    
    // Slider
    var minSliderColour: UIColor {
        isSender ? .white : .speezyPurple
    }
    
    var maxSliderColour: UIColor {
        minSliderColour.withAlphaComponent(0.3)
    }
    
    var sliderThumbColour: UIColor {
        isSender ? .white : .speezyPurple
    }
    
    var sliderBorderColor: UIColor {
        isSender ? .white : .speezyPurple
    }
}
