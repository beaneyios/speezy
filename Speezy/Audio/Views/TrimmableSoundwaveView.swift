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

protocol TrimmableSoundWaveViewDelegate: AnyObject {
    func trimViewDidApplyTrim(_ view: TrimmableSoundwaveView)
    func trimViewDidCancelTrim(_ view: TrimmableSoundwaveView)
}

class TrimmableSoundwaveView: UIView {
    
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var waveContainer: UIView!
    
    @IBOutlet weak var leftHandle: UIView!
    @IBOutlet weak var rightHandle: UIView!
    
    @IBOutlet weak var leftHandleConstraint: NSLayoutConstraint!
    @IBOutlet weak var rightHandleConstraint: NSLayoutConstraint!
    
    weak var delegate: TrimmableSoundWaveViewDelegate?
    
    private var trimWave: AudioVisualizationView!
    
    private let barSpacing: CGFloat = 1.0
    private let barWidth: CGFloat = 1.0
    private var totalSpacePerBar: CGFloat { barSpacing + barWidth }
        
    private var lastLeftLocation: CGFloat = 0.0
    private var lastRightLocation: CGFloat = 0.0
    
    private var manager: AudioManager?
    
    func configure(manager: AudioManager) {
        self.manager = manager
        setUpHandles()
        layoutIfNeeded()
        render()
    }
    
    private func render() {
        guard let manager = self.manager else {
            assertionFailure("Manager not available for some reason")
            return
        }
        
        AudioLevelGenerator.render(fromAudioURL: manager.item.url, targetSamplesPolicy: .fitToWidth(width: frame.width, barSpacing: barSpacing)) { (audioData) in
            DispatchQueue.main.async {
                self.createAudioVisualisationView(with: audioData.percentageLevels)
            }
        }
    }
    
    private func createAudioVisualisationView(with levels: [Float]) {
        
        let waveSize = CGSize(
            width: waveContainer.frame.width,
            height: waveContainer.frame.height
        )
                    
        let trimWave = AudioVisualizationView(
            frame: CGRect(
                x: 0,
                y: 0.0,
                width: waveSize.width,
                height: waveSize.height
            )
        )
        
        trimWave.gradientEndColor = .red
        trimWave.gradientStartColor = .white
        trimWave.meteringLevelBarInterItem = barSpacing
        trimWave.meteringLevelBarWidth = barWidth
        trimWave.audioVisualizationMode = .read
        trimWave.meteringLevels = levels
        
        trimWave.tintColor = .white
        trimWave.backgroundColor = .clear
        trimWave.alpha = 0.0
                    
        waveContainer.addSubview(trimWave)
        contentView.bringSubviewToFront(leftHandle)
        contentView.bringSubviewToFront(rightHandle)
        self.trimWave = trimWave
        
        UIView.animate(withDuration: 0.4) {
            trimWave.alpha = 1.0
        }
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
            if newConstraint > 0 {
                lastLeftLocation = newConstraint
            } else {
                lastLeftLocation = 0.0
            }
                        
            trim()
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
            
            if newConstraint > 0 {
                lastRightLocation = newConstraint
            } else {
                lastRightLocation = 0.0
            }
            
            trim()
        }
    }
    
    @IBAction func applyTrim(_ sender: Any) {
        delegate?.trimViewDidApplyTrim(self)
    }
    
    @IBAction func cancelTrim(_ sender: Any) {
        delegate?.trimViewDidCancelTrim(self)
    }
    
    private func trim() {
        if let manager = manager {
            let percentageStart = lastLeftLocation / contentView.frame.width
            let percentageEnd = (contentView.frame.width - lastRightLocation) / contentView.frame.width
            let durationStart = manager.duration * TimeInterval(percentageStart)
            let durationEnd = manager.duration * TimeInterval(percentageEnd)
            
            manager.trim(from: durationStart, to: durationEnd)
        }
    }
}

extension TrimmableSoundwaveView {
    class func instanceFromNib() -> TrimmableSoundwaveView {
        return UINib(nibName: "TrimmableSoundwaveView", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! TrimmableSoundwaveView
    }
}
