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
    @IBOutlet weak var sendContainer: UIView!
    
    @IBOutlet var firstWaveAnimations: [UIView]!
    @IBOutlet var secondWaveAnimations: [UIView]!
    
    @IBOutlet weak var slider: CustomSlider!
    @IBOutlet weak var titleField: UITextField!
    
    var sendAction: (() -> Void)?
    var textChangeAction: ((String) -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        [editAudioContainer, sendContainer].forEach {
            $0?.layer.cornerRadius = 10.0
            $0?.layer.borderWidth = 1.0
        }
        
        editAudioContainer.layer.borderColor = UIColor.speezyPurple.cgColor
        sendContainer.layer.borderColor = UIColor.speezyDarkRed.cgColor
        
        slider.thumbColour = .white
        slider.minimumTrackTintColor = .white
        slider.maximumTrackTintColor = UIColor.white.withAlphaComponent(0.3)
        slider.borderColor = .white
        slider.thumbRadius = 12
        slider.depressedThumbRadius = 15
        slider.configure()
        
        titleField.delegate = self
    }
    
    @IBAction func editAudioTapped(_ sender: Any) {
        editAudioContainer.alpha = 1.0
    }
    
    @IBAction func sendTapped(_ sender: Any) {
        sendContainer.alpha = 1.0
        sendAction?()
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

extension ChatPlaybackView: UITextFieldDelegate {
    func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        
        guard let textFieldText = textField.text else {
            return true
        }
        
        let nsText = textFieldText as NSString
        let newString = nsText.replacingCharacters(
            in: range,
            with: string
        )
        
        textChangeAction?(newString)        
        return true
    }
}
