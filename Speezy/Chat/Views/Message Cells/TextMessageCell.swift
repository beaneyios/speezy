//
//  TextMessageCell.swift
//  Speezy
//
//  Created by Matt Beaney on 10/04/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import UIKit

class TextMessageCell: UICollectionViewCell, NibLoadable {

    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var displayName: UILabel!
    @IBOutlet weak var timestampLabel: UILabel!
    
    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var sendStatusImage: UIImageView!
    @IBOutlet weak var sendStatusImageWidth: NSLayoutConstraint!
    @IBOutlet weak var sendStatusPadding: NSLayoutConstraint!
    @IBOutlet weak var unplayedNotification: UIView!
    @IBOutlet weak var unplayedNotificationPadding: NSLayoutConstraint!
    @IBOutlet weak var messageContainer: UIView!
    
    private(set) var message: Message?
    var longPressTapped: ((Message) -> Void)?
    
    func configure(item: MessageCellModel) {
        self.message = item.message
        
        messageLabel.text = item.messageText
        messageLabel.textColor = item.messageTint
        
        profileImage.image = item.profileImage
        
        timestampLabel.text = item.timestampText
        timestampLabel.textColor = item.timestampTint
        
        sendStatusImage.tintColor = item.tickTint
        
        displayName.text = item.displayNameText
        displayName.textColor = item.displayNameTint
        
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
        
        messageContainer.backgroundColor = item.backgroundColor
        messageContainer.layer.cornerRadius = 30.0
                        
        sendStatusImage.alpha = item.tickOpacity
        sendStatusImageWidth.constant = item.tickWidth
        sendStatusPadding.constant = item.tickPadding
        
                
        let longTap = UILongPressGestureRecognizer(target: self, action: #selector(longPressedCell))
        addGestureRecognizer(longTap)

        configureImage(item: item)
        
        setNeedsLayout()
        layoutIfNeeded()
        profileImage.layer.cornerRadius = profileImage.frame.height / 2.0
    }
    
    func configureImage(item: MessageCellModel) {
        item.loadImage { (result) in
            switch result {
            case let .success(image):
                self.profileImage.image = image
            case let .failure(error):
                self.profileImage.image = item.profileImage
            }
        }
    }
    
    @objc private func longPressedCell() {
        guard let message = message else {
            return
        }
        
        longPressTapped?(message)
    }
}
