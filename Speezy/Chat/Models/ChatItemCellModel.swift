//
//  ChatItem.swift
//  Speezy
//
//  Created by Matt Beaney on 11/01/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import UIKit

struct ChatItemCellModel {
    var displayName: String
    var profileImage: UIImage?
    var timeStamp: String
        
    var isSender: Bool
    var received: Bool?
    
    var message: String?
    var audioUrl: URL?
    var attachmentUrl: URL?
    
    var duration: TimeInterval
    
    var tickTint: UIColor? {
        guard let received = self.received else {
            return nil
        }
        
        let receivedTint = UIColor.speezyPurple
        let notReceivedTint = UIColor.speezyDarkGrey
        return received ? receivedTint : notReceivedTint
    }
    
    var backgroundImage: UIImage? {
        isSender ? UIImage(named: "gradient-background") : nil
    }
    
    var messageTint: UIColor {
        isSender ? .white : .black
    }
    
    var timestampTint: UIColor {
        isSender ? .white : .darkGray
    }
    
    var durationTint: UIColor {
        isSender ? .white : .darkGray
    }
    
    var playButtonTint: UIColor {
        isSender ? .white : .speezyPurple
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
