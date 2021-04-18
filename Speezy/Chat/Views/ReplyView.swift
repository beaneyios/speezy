//
//  ReplyView.swift
//  Speezy
//
//  Created by Matt Beaney on 18/04/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import UIKit

struct ReplyViewModel {
    var chatterText: String
    var messageText: String?
    var durationText: String?
    
    var chatterColor: UIColor?
}

class ReplyView: UIView, NibLoadable {
    
    @IBOutlet weak var chatterLabel: UILabel!
    @IBOutlet weak var audioLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    
    var closeTapped: (() -> Void)?
    
    func configure(viewModel: ReplyViewModel) {
        self.chatterLabel.text = viewModel.chatterText
        self.messageLabel.text = viewModel.messageText
        self.audioLabel.text = viewModel.durationText
        
        self.chatterLabel.textColor = viewModel.chatterColor ?? .black
    }
    
    @IBAction func didTapClose(_ sender: Any) {
        closeTapped?()
    }
}
