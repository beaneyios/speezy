//
//  AudioChatItemCell.swift
//  Speezy
//
//  Created by Matt Beaney on 11/01/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import UIKit

class MessageCell: UICollectionViewCell, NibLoadable {
    @IBOutlet weak var slider: CustomSlider!
    
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var profileImage: UIImageView!
    
    @IBOutlet weak var durationLabel: UILabel!
    
    @IBOutlet weak var timestampLabel: UILabel!
    @IBOutlet weak var sendStatusImage: UIImageView!
    @IBOutlet weak var sendStatusImageWidth: NSLayoutConstraint!
    
    @IBOutlet weak var messageContainer: UIView!
    @IBOutlet weak var messageBackgroundImage: UIImageView!
    
    @IBOutlet weak var playButtonImage: UIImageView!
        
    func configure(item: MessageCellModel) {
        playButtonImage.tintColor = item.playButtonTint
        
        messageLabel.text = item.messageText
        messageLabel.textColor = item.messageTint
        
        profileImage.image = item.profileImage
        
        timestampLabel.text = item.timestampText
        timestampLabel.textColor = item.timestampTint
        
        sendStatusImage.tintColor = item.tickTint
        
        messageContainer.layer.maskedCorners = {
            if item.isSender {
                return [
                    .layerMinXMinYCorner,
                    .layerMinXMaxYCorner,
                    .layerMaxXMinYCorner
                ]
            } else {
                return [
                    .layerMinXMinYCorner,
                    .layerMaxXMaxYCorner,
                    .layerMaxXMinYCorner
                ]
            }
        }()
        
        messageContainer.layer.cornerRadius = 30.0
        messageBackgroundImage.image = item.backgroundImage
        
        durationLabel.text = item.durationText
        durationLabel.textColor = item.durationTint
        
        sendStatusImage.alpha = item.tickOpacity
        sendStatusImageWidth.constant = item.tickWidth
        
        slider.thumbColour = item.sliderThumbColour
        slider.minimumTrackTintColor = item.minSliderColour
        slider.maximumTrackTintColor = item.maxSliderColour
        slider.borderColor = item.sliderBorderColor        
        slider.configure()
    }
}
