//
//  ChatPlaybackView.swift
//  Speezy
//
//  Created by Matt Beaney on 19/01/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import UIKit

class ChatPlaybackView: UIView, NibLoadable {
    @IBOutlet weak var editAudioContainer: UIView!
    @IBOutlet weak var addMessageContainer: UIView!
    @IBOutlet weak var sendContainer: UIView!
    
    @IBOutlet var firstWaveAnimations: [UIView]!
    @IBOutlet var secondWaveAnimations: [UIView]!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        [editAudioContainer, addMessageContainer, sendContainer].forEach {
            $0?.layer.cornerRadius = 10.0
            $0?.layer.borderWidth = 1.0
        }
        
        editAudioContainer.layer.borderColor = UIColor.speezyPurple.cgColor
        addMessageContainer.layer.borderColor = UIColor.speezyPurple.cgColor
        sendContainer.layer.borderColor = UIColor.speezyDarkRed.cgColor
    }
    
    @IBAction func editAudioTapped(_ sender: Any) {
        editAudioContainer.alpha = 1.0
    }
    
    @IBAction func addMessageTapped(_ sender: Any) {
        addMessageContainer.alpha = 1.0
    }
    
    @IBAction func sendTapped(_ sender: Any) {
        sendContainer.alpha = 1.0
    }
    
    @IBAction func buttonPressed(_ sender: UIButton) {
        sender.superview?.alpha = 0.9
    }
    
    func animateIn() {
        (firstWaveAnimations + secondWaveAnimations).forEach {
            $0.alpha = 0.0
            $0.transform = CGAffineTransform(translationX: -30.0, y: 1.0)
        }
        
        firstWaveAnimations.enumerated().forEach {
            let viewToAnimate = $0.element
            UIView.animate(
                withDuration: 0.2,
                delay: Double($0.offset) / 10.0,
                options: []
            ) {
                viewToAnimate.alpha = 1.0
                viewToAnimate.transform = CGAffineTransform.identity
            } completion: { _ in
                
            }
        }
        
        secondWaveAnimations.enumerated().forEach {
            let viewToAnimate = $0.element
            UIView.animate(
                withDuration: 0.2,
                delay: Double($0.offset) / 10.0,
                options: []
            ) {
                viewToAnimate.alpha = 1.0
                viewToAnimate.transform = CGAffineTransform.identity
            } completion: { _ in
                
            }
        }
    }
}
