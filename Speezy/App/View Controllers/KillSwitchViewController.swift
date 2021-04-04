//
//  KillSwitchViewController.swift
//  Speezy
//
//  Created by Matt Beaney on 14/03/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import UIKit
import Lottie

class KillSwitchViewController: UIViewController {
    
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var animationContainer: UIView!
    
    var status: Status!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        titleLabel.text = status.title
        messageLabel.text = status.message
        
        let animationView = AnimationView()
        let animation = Animation.named("maintenance")
        animationView.animation = animation
        animationView.play()
        animationView.play(
            fromProgress: 0,
            toProgress: 1,
            loopMode: LottieLoopMode.loop
        )
        animationContainer.addSubview(animationView)
        
        animationView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
}
