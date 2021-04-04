//
//  ChatCell.swift
//  Speezy
//
//  Created by Matt Beaney on 23/01/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import UIKit

class ChatCell: UICollectionViewCell, NibLoadable {
    @IBOutlet weak var chatTitleLabel: UILabel!
    @IBOutlet weak var lastMessageLabel: UILabel!
    @IBOutlet weak var lastUpdatedLabel: UILabel!
    @IBOutlet weak var chatImage: UIImageView!
    @IBOutlet weak var chatImageFrame: UIView!
    @IBOutlet weak var notificationLabel: UILabel!
    
    override func layoutSubviews() {
        super.layoutSubviews()
        chatImage.layer.cornerRadius = chatImage.frame.width / 2.0
        chatImageFrame.layer.cornerRadius = chatImageFrame.frame.width / 2.0
        chatImageFrame.layer.borderWidth = 1.0
        chatImageFrame.layer.borderColor = UIColor.speezyPurple.cgColor
        
        notificationLabel.layer.cornerRadius = notificationLabel.frame.width / 2.0
        notificationLabel.clipsToBounds = true
    }
    
    func configure(item: ChatCellModel) {
        chatTitleLabel.text = item.titleText
        lastMessageLabel.text = item.lastMessageText
        lastUpdatedLabel.text = item.lastUpdatedText
        chatImage.image = nil
        chatImage.alpha = 0.0
        
        configureNotificationLabel(item: item)
        
        item.loadImage { (result) in
            DispatchQueue.main.async {
                switch result {
                case let .success(image):
                    self.chatImage.image = image
                    UIView.animate(withDuration: 1.0) {
                        self.chatImage.alpha = 1.0
                    }
                case .failure:
                    self.chatImage.alpha = 1.0
                    self.chatImage.image = UIImage(named: "account-btn")
                }
            }
        }
    }
    
    func configureNotificationLabel(item: ChatCellModel) {
        lastMessageLabel.text = item.lastMessageText
        notificationLabel.isHidden = item.showRead
    }
}
