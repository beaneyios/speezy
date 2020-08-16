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
    
    private var manager: AudioManager!
    
    func configure(with manager: AudioManager) {
        self.manager = manager
        manager.addObserver(self)
        
        sliderPlayback.addTarget(
            self,
            action: #selector(onSliderValChanged(slider:event:)),
            for: .valueChanged
        )
    }
    
    @IBAction func skipBackward(_ sender: Any) {
        var newTime = manager.currentPlaybackTime - 10
        if newTime < 0 {
            newTime = 0
        }
        
        let percentage = Float(newTime / manager.currentItem.duration)
        manager.seek(to: percentage)
    }
    
    @IBAction func skipForward(_ sender: Any) {
        var newTime = manager.currentPlaybackTime + 10
        if newTime > manager.currentItem.duration {
            newTime = manager.currentItem.duration
        }
        
        let percentage = Float(newTime / manager.currentItem.duration)
        manager.seek(to: percentage)
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
                if case AudioManager.State.startedPlayback = manager.state {
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

extension PlaybackControlsView: AudioManagerObserver {
    func audioManager(_ player: AudioManager, didStartPlaying item: AudioItem) {
        btnPlayback.setImage(UIImage(named: "pause-button"), for: .normal)
    }
    
    func audioManager(_ player: AudioManager, didPausePlaybackOf item: AudioItem) {
        btnPlayback.setImage(UIImage(named: "play-button"), for: .normal)
    }
    
    func audioManager(_ player: AudioManager, didStopPlaying item: AudioItem) {
        btnPlayback.setImage(UIImage(named: "play-button"), for: .normal)
        sliderPlayback.setValue(0.0, animated: true)
    }
    
    func audioManager(_ player: AudioManager, progressedWithTime time: TimeInterval) {
        let percentageComplete = time / manager.currentItem.duration
        self.sliderPlayback.setValue(Float(percentageComplete), animated: false)
    }
    
    func audioManager(_ player: AudioManager, didAdjustCropOnItem item: AudioItem) {
        resetSlider()
    }
    
    func audioManager(_ player: AudioManager, didFinishCroppingItem item: AudioItem) {
        resetSlider()
    }
    
    func audioManagerDidCancelCropping(_ player: AudioManager) {
        resetSlider()
    }
    
    func audioManager(_ player: AudioManager, didConfirmCropOnItem item: AudioItem) {}
    func audioManager(_ player: AudioManager, didMoveLeftCropHandleTo percentage: CGFloat) {}
    func audioManager(_ player: AudioManager, didMoveRightCropHandleTo percentage: CGFloat) {}
    func audioManager(_ player: AudioManager, didStartCroppingItem item: AudioItem) {}
    
    func audioManagerDidStartRecording(_ player: AudioManager) {}
    func audioManager(_ player: AudioManager, didRecordBarWithPower decibel: Float, stepDuration: TimeInterval, totalDuration: TimeInterval) {}
    func audioManagerProcessingRecording(_ player: AudioManager) {}
    func audioManagerDidStopRecording(_ player: AudioManager) {}
    func audioManager(_ player: AudioManager, didReachMaxRecordingLimitWithItem item: AudioItem) {}
}

extension PlaybackControlsView {
    class func instanceFromNib() -> PlaybackControlsView {
        return UINib(nibName: "PlaybackControlsView", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! PlaybackControlsView
    }
}
