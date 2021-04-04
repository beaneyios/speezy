//
//  ChatRecordView.swift
//  Speezy
//
//  Created by Matt Beaney on 19/01/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import UIKit

class ChatRecordView: UIView, NibLoadable {
    var recordAction: (() -> Void)?
    var textAction: (() -> Void)?
    
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var textButton: UIButton!
    
    @IBAction func recordButtonTapped(_ sender: Any) {
        recordAction?()
    }
    
    @IBAction func textChatTapped(_ sender: Any) {
        textAction?()
    }
    
    func animateIn() {
        recordButton.transform = CGAffineTransform(scaleX: 1.4, y: 1.4)
        textButton.transform = CGAffineTransform(scaleX: 1.4, y: 1.4)
        
        UIView.animate(withDuration: 0.3, delay: 0.1, options: []) {
            self.recordButton.transform = CGAffineTransform.identity
            self.textButton.transform = CGAffineTransform.identity
        } completion: { _ in
            
        }
    }
    
    func animateOut() {
        UIView.animate(withDuration: 0.3) {
            self.recordButton.transform = CGAffineTransform(
                scaleX: 0.1,
                y: 0.1
            )
            self.textButton.transform = CGAffineTransform(
                scaleX: 0.1,
                y: 0.1
            )
        }
    }
}
