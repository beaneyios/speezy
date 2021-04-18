//
//  ReplyMessageEmbedView.swift
//  Speezy
//
//  Created by Matt Beaney on 18/04/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import UIKit

struct ReplyMessageEmbedViewModel {
    let message: MessageReply
    let sender: Bool
    let chatterColor: UIColor
    
    var chatterText: String {
        message.chatter.displayName
    }
    
    var durationString: String? {
        return message.duration?.formattedString
    }
    
    var messageText: String {
        if let message = message.message {
            return message
        } else{
            return "Audio"
        }
    }
    
    var durationTextColor: UIColor {
        .white
    }
    
    var chatterTextColor: UIColor {
        .white
    }
    
    var messageTextColor: UIColor {
        .white
    }
    
    var backgroundColor: UIColor {
        UIColor.lightGray.withAlphaComponent(0.6)
    }
    
    init(message: MessageReply, sender: Bool, chatterColor: UIColor) {
        self.message = message
        self.sender = sender
        self.chatterColor = chatterColor
    }
}

class ReplyMessageEmbedView: UIView, NibLoadable {
    @IBOutlet weak var chatterLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    
    func configure(viewModel: ReplyMessageEmbedViewModel) {
        chatterLabel.text = viewModel.chatterText
        messageLabel.text = viewModel.messageText
        durationLabel.text = viewModel.durationString
        
        chatterLabel.textColor = viewModel.chatterTextColor
        messageLabel.textColor = viewModel.messageTextColor
        durationLabel.textColor = viewModel.durationTextColor
        
        backgroundColor = viewModel.backgroundColor
        layer.cornerRadius = 15.0
        layer.borderColor = viewModel.chatterColor.withAlphaComponent(0.6).cgColor
        layer.borderWidth = 1.0
        clipsToBounds = true
    }
}
