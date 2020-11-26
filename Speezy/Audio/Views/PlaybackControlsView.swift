//
//  PlaybackControlsView.swift
//  Speezy
//
//  Created by Matt Beaney on 05/08/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import UIKit

class PlaybackControlsView: UIView, NibLoadable {
    @IBOutlet weak var btnPlayback: UIButton!
    @IBOutlet weak var sliderPlayback: UISlider!
    
    @IBOutlet var recordHidables: [UIButton]!
    
    private var manager: AudioManager!
    
    func configure(with manager: AudioManager) {
        self.manager = manager
        manager.addPlaybackObserver(self)
        manager.addRecorderObserver(self)
        manager.addCropperObserver(self)
        manager.addCropperObserver(self)
        
        sliderPlayback.addTarget(
            self,
            action: #selector(onSliderValChanged(slider:event:)),
            for: .valueChanged
        )
    }
    
    @IBAction func skipBackward(_ sender: Any) {
        
    }
    
    @IBAction func skipForward(_ sender: Any) {
        
    }
    
    @IBAction func togglePlayback(_ sender: Any) {
        manager.togglePlayback()
    }
    
    private func resetSlider() {
        sliderPlayback.setValue(0.0, animated: true)
    }
    
    private var wasPlaying: Bool = false
    @objc func onSliderValChanged(slider: UISlider, event: UIEvent) {
        if let touchEvent = event.allTouches?.first {
            switch touchEvent.phase {
            case .began:
                if case AudioState.startedPlayback = manager.state {
                    wasPlaying = true
                } else {
                    wasPlaying = false
                }
                
                manager.pause()
            case .moved:
                manager.seek(to: slider.value)
            case .ended:
                if wasPlaying {
                    manager.play()
                }
            default:
                break
            }
        }
    }
}

extension PlaybackControlsView: AudioPlayerObserver {
    func playBackBegan(on item: AudioItem) {
        btnPlayback.setImage(UIImage(named: "pause-button"), for: .normal)
    }
    
    func playbackPaused(on item: AudioItem) {
        btnPlayback.setImage(UIImage(named: "play-button"), for: .normal)
    }
    
    func playbackStopped(on item: AudioItem) {
        btnPlayback.setImage(UIImage(named: "play-button"), for: .normal)
        sliderPlayback.setValue(0.0, animated: true)
    }
    
    func playbackProgressed(
        withTime time: TimeInterval,
        seekActive: Bool,
        onItem item: AudioItem,
        startOffset: TimeInterval
    ) {
        if seekActive {
            return
        }
        
        let percentageComplete = time / manager.currentItem.duration
        self.sliderPlayback.setValue(Float(percentageComplete), animated: false)
    }
}

extension PlaybackControlsView: AudioRecorderObserver {
    func recordingBegan() {
        recordHidables.forEach {
            $0.isEnabled = false
            $0.alpha = 0.6
        }
        
        sliderPlayback.isEnabled = false
    }
    
    func recordedBar(withPower decibel: Float, stepDuration: TimeInterval, totalDuration: TimeInterval) {
        
    }
    
    func recordingProcessing() {
        
    }
    
    func recordingStopped(maxLimitedReached: Bool) {
        recordHidables.forEach {
            $0.isEnabled = true
            $0.alpha = 1.0
        }
        
        sliderPlayback.isEnabled = true
    }
}

extension PlaybackControlsView: AudioCropperObserver {
    func cropRangeAdjusted(onItem item: AudioItem) {
        resetSlider()
    }
    
    func croppingFinished(onItem item: AudioItem) {
        resetSlider()
    }
    
    func croppingCancelled() {
        resetSlider()
    }
    
    func croppingStarted(onItem item: AudioItem) {}
    func leftCropHandle(movedToPercentage percentage: CGFloat) {}
    func rightCropHandle(movedToPercentage percentage: CGFloat) {}
}

extension PlaybackControlsView: AudioCutterObserver {
    func cutRangeAdjusted(onItem item: AudioItem) {
        resetSlider()
    }
    
    func cuttingFinished(onItem item: AudioItem) {
        resetSlider()
    }
    
    func cuttingCancelled() {
        resetSlider()
    }
    
    func cuttingStarted(onItem item: AudioItem) {}
}

extension PlaybackControlsView {
    class func instanceFromNib() -> PlaybackControlsView {
        return UINib(nibName: "PlaybackControlsView", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! PlaybackControlsView
    }
}
