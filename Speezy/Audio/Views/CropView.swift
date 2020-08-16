//
//  CropView.swift
//  Speezy
//
//  Created by Matt Beaney on 12/07/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import Foundation
import UIKit

class CropView: UIView {
    
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var waveContainer: UIView!
    
    @IBOutlet weak var leftHandle: UIView!
    @IBOutlet weak var rightHandle: UIView!
    
    @IBOutlet weak var leftHandleConstraint: NSLayoutConstraint!
    @IBOutlet weak var rightHandleConstraint: NSLayoutConstraint!
        
    private var cropWave: AudioVisualizationView!
    
    private let barSpacing: CGFloat = 0.5
    private let barWidth: CGFloat = 0.5
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
        
        AudioLevelGenerator.render(fromAudioItem: manager.item, targetSamplesPolicy: .fitToWidth(width: frame.width, barSpacing: barSpacing + barWidth)) { (audioData) in
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
                    
        let cropWave = AudioVisualizationView(
            frame: CGRect(
                x: 0,
                y: 0.0,
                width: waveSize.width,
                height: waveSize.height
            )
        )
        
        cropWave.gradientEndColor = .red
        cropWave.gradientStartColor = .white
        cropWave.meteringLevelBarInterItem = barSpacing
        cropWave.meteringLevelBarWidth = barWidth
        cropWave.audioVisualizationMode = .read
        cropWave.meteringLevels = levels
        
        cropWave.tintColor = .white
        cropWave.backgroundColor = .clear
        cropWave.alpha = 0.0
                    
        waveContainer.addSubview(cropWave)
        contentView.bringSubviewToFront(leftHandle)
        contentView.bringSubviewToFront(rightHandle)
        self.cropWave = cropWave
        
        UIView.animate(withDuration: 0.4) {
            cropWave.alpha = 1.0
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
            if newConstraint < 2 {
                leftHandleConstraint.constant = 0.0
                lastLeftLocation = 0.0
                notifyLeftPanMoved()
                return
            }
            
            if (newConstraint + 48.0) > rightHandle.frame.minX {
                return
            }
            
            leftHandleConstraint.constant = newConstraint
            layoutIfNeeded()
            
            notifyLeftPanMoved()
        }
        
        if sender.state == .ended {
            if newConstraint > 0 {
                lastLeftLocation = leftHandleConstraint.constant
            } else {
                lastLeftLocation = 0.0
            }
                        
            crop()
        }
    }
    
    private func notifyLeftPanMoved() {
        let percentage = leftHandleConstraint.constant / contentView.frame.width
        manager?.leftCropHandleMoved(to: percentage)
    }
    
    private func notifyRightPanMoved() {
        let percentage = (contentView.frame.width - rightHandleConstraint.constant) / contentView.frame.width
        manager?.rightCropHandleMoved(to: percentage)
    }
    
    @objc func rightPan(sender: UIPanGestureRecognizer) {
        layoutIfNeeded()
        
        let translation = sender.translation(in: contentView)
        let newConstraint = lastRightLocation - translation.x
        
        if sender.state == .changed {
            if newConstraint < 2 {
                rightHandleConstraint.constant = 0.0
                lastRightLocation = 0.0
                notifyRightPanMoved()
                return
            }
            
            if (newConstraint + 48.0) > (contentView.frame.width - leftHandle.frame.maxX) {
                return
            }
            
            rightHandleConstraint.constant = newConstraint
            layoutIfNeeded()
            
            notifyRightPanMoved()
        }
        
        if sender.state == .ended {
            if rightHandleConstraint.constant > 0 {
                lastRightLocation = rightHandleConstraint.constant
            } else {
                lastRightLocation = 0.0
            }
            
            crop()
        }
    }
    
    private func crop() {
        if let manager = manager {
            let percentageStart = lastLeftLocation / contentView.frame.width
            let percentageEnd = (contentView.frame.width - lastRightLocation) / contentView.frame.width
            let durationStart = manager.duration * TimeInterval(percentageStart)
            let durationEnd = manager.duration * TimeInterval(percentageEnd)
            
            manager.crop(from: durationStart, to: durationEnd)
        }
    }
}

extension CropView {
    class func instanceFromNib() -> CropView {
        return UINib(nibName: "CropView", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! CropView
    }
}
