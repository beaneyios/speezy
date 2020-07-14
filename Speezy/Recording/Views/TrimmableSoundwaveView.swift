//
//  TrimmableSoundwaveView.swift
//  Speezy
//
//  Created by Matt Beaney on 12/07/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import Foundation
import UIKit
import SoundWave

class TrimmableSoundwaveView: UIView {
    
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var audioContentView: UIView!
    
    @IBOutlet weak var leftHandle: UIView!
    @IBOutlet weak var rightHandle: UIView!
    
    @IBOutlet weak var leftHandleConstraint: NSLayoutConstraint!
    @IBOutlet weak var rightHandleConstraint: NSLayoutConstraint!
    
    private var audioVisualizationView: AudioVisualizationView!
    
    private let barSpacing: CGFloat = 1.0
    private let barWidth: CGFloat = 1.0
    private var totalSpacePerBar: CGFloat { barSpacing + barWidth }
        
    private var lastLeftLocation: CGFloat = 16.0
    private var lastRightLocation: CGFloat = 16.0
    
    func configure(with url: URL) {
        setUpHandles()

        AudioLevelGenerator.render(fromAudioURL: url, targetSamplesPolicy: .fitToWidth(width: frame.width, barSpacing: barSpacing)) { (levels, _) in
            DispatchQueue.main.async {
                self.createAudioVisualisationView(with: levels)
            }
        }
    }
    
    private func createAudioVisualisationView(with levels: [Float]) {
        
        let audioVisualizationViewSize = CGSize(
            width: audioContentView.frame.width,
            height: audioContentView.frame.height
        )
                    
        let audioVisualizationView = AudioVisualizationView(
            frame: CGRect(
                x: 0,
                y: 0.0,
                width: audioVisualizationViewSize.width,
                height: audioVisualizationViewSize.height
            )
        )
        
        audioVisualizationView.gradientEndColor = .red
        audioVisualizationView.gradientStartColor = .white
        audioVisualizationView.meteringLevelBarInterItem = self.barSpacing
        audioVisualizationView.meteringLevelBarWidth = self.barWidth
        audioVisualizationView.tintColor = .white
        audioVisualizationView.audioVisualizationMode = .read
        audioVisualizationView.backgroundColor = .clear
        audioVisualizationView.meteringLevels = levels
                    
        self.audioContentView.addSubview(audioVisualizationView)
        contentView.bringSubviewToFront(leftHandle)
        contentView.bringSubviewToFront(rightHandle)
        self.audioVisualizationView = audioVisualizationView
    }
    
    func setUpHandles() {
        let panRight = UIPanGestureRecognizer(target: self, action: #selector(rightPan(sender:)))
        rightHandle.addGestureRecognizer(panRight)
        rightHandle.isUserInteractionEnabled = true
        
        let panLeft = UIPanGestureRecognizer(target: self, action: #selector(leftPan(sender:)))
        leftHandle.addGestureRecognizer(panLeft)
        leftHandle.isUserInteractionEnabled = true
    }
    
    @objc func leftPan(sender: UIPanGestureRecognizer) {
        layoutIfNeeded()
        
        let translation = sender.translation(in: contentView)
        let newConstraint = lastLeftLocation + translation.x
        
        if sender.state == .changed {
            if newConstraint < 0 {
                leftHandleConstraint.constant = 0.0
                lastLeftLocation = 0.0
                return
            }
            
            if (newConstraint + 48.0) > rightHandle.frame.minX {
                return
            }
            
            leftHandleConstraint.constant = newConstraint
            layoutIfNeeded()
        }
        
        if sender.state == .ended {
            lastLeftLocation = newConstraint
        }
    }
    
    @objc func rightPan(sender: UIPanGestureRecognizer) {
        layoutIfNeeded()
        
        let translation = sender.translation(in: contentView)
        let newConstraint = lastRightLocation - translation.x
        
        if sender.state == .changed {
            if newConstraint < 0 {
                rightHandleConstraint.constant = 0.0
                lastRightLocation = 0.0
                return
            }
            
            if (newConstraint + 48.0) > (contentView.frame.width - leftHandle.frame.maxX) {
                return
            }
            
            rightHandleConstraint.constant = newConstraint
            layoutIfNeeded()
        }
        
        if sender.state == .ended {
            lastRightLocation = newConstraint
        }
    }
}

extension TrimmableSoundwaveView {
    class func instanceFromNib() -> TrimmableSoundwaveView {
        return UINib(nibName: "TrimmableSoundwaveView", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! TrimmableSoundwaveView
    }
}
