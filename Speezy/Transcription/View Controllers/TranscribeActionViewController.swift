//
//  TranscribeActionViewController.swift
//  Speezy
//
//  Created by Matt Beaney on 26/10/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import UIKit

protocol TranscribeActionViewControllerDelegate: AnyObject {
    func transcribeActionViewControllerDidSelectTranscribe(_ viewController: TranscribeActionViewController)
}

class TranscribeActionViewController: UIViewController {
    
    @IBOutlet weak var transcribeButtonContainer: UIView!
    @IBOutlet weak var loadingBubble: UIImageView!
    @IBOutlet weak var actionText: UILabel!
    
    weak var delegate: TranscribeActionViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        transcribeButtonContainer.layer.cornerRadius = 10.0
    }
    
    @IBAction func transcribeTapped(_ sender: Any) {
        UIView.animate(withDuration: 0.4) {
            self.transcribeButtonContainer.alpha = 0.0
            self.actionText.alpha = 0.0
            self.loadingBubble.transform = CGAffineTransform(
                translationX: 0,
                y: 56
            )
        } completion: { (finished) in
            self.delegate?.transcribeActionViewControllerDidSelectTranscribe(self)
        }
    }
}
