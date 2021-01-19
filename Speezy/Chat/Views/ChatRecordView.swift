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
    
    @IBOutlet weak var recordButton: UIButton!
    
    @IBAction func recordButtonTapped(_ sender: Any) {
        recordAction?()
    }
    
    func animateIn() {
        recordButton.transform = CGAffineTransform(scaleX: 1.4, y: 1.4)
        
        UIView.animate(withDuration: 0.3, delay: 0.1, options: []) {
            self.recordButton.transform = CGAffineTransform.identity
        } completion: { _ in
            
        }
    }
}
