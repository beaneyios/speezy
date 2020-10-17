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
        manager.addPlayerObserver(self)
        manager.addRecorderObserver(self)
        manager.addCropperObserver(self)
        
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

extension PlaybackControlsView: AudioPlayerObserver {
    func audioManager(_ manager: AudioManager, didStartPlaying item: AudioItem) {
        btnPlayback.setImage(UIImage(named: "pause-button"), for: .normal)
    }
    
    func audioManager(_ manager: AudioManager, didPausePlaybackOf item: AudioItem) {
        btnPlayback.setImage(UIImage(named: "play-button"), for: .normal)
    }
    
    func audioManager(_ manager: AudioManager, didStopPlaying item: AudioItem) {
        btnPlayback.setImage(UIImage(named: "play-button"), for: .normal)
        sliderPlayback.setValue(0.0, animated: true)
    }
    
    func audioManager(_ manager: AudioManager, progressedWithTime time: TimeInterval, seekActive: Bool) {
        if seekActive {
            return
        }
        
        let percentageComplete = time / manager.currentItem.duration
        self.sliderPlayback.setValue(Float(percentageComplete), animated: false)
    }
}

extension PlaybackControlsView: AudioRecorderObserver {
    func audioManagerDidStartRecording(_ player: AudioManager) {
        recordHidables.forEach {
            $0.isEnabled = false
            $0.alpha = 0.6
        }
        
        sliderPlayback.isEnabled = false
    }
    
    func audioManagerDidStopRecording(_ player: AudioManager, maxLimitedReached: Bool) {
        recordHidables.forEach {
            $0.isEnabled = true
            $0.alpha = 1.0
        }
        
        sliderPlayback.isEnabled = true
    }
    
    func audioManager(_ manager: AudioManager, didRecordBarWithPower decibel: Float, stepDuration: TimeInterval, totalDuration: TimeInterval) {}
    func audioManagerProcessingRecording(_ player: AudioManager) {}
}

extension PlaybackControlsView: AudioCropperObserver {
    func audioManager(_ manager: AudioManager, didAdjustCropOnItem item: AudioItem) {
        resetSlider()
    }
    
    func audioManager(_ manager: AudioManager, didFinishCroppingItem item: AudioItem) {
        resetSlider()
    }
    
    func audioManagerDidCancelCropping(_ player: AudioManager) {
        resetSlider()
    }
    
    func audioManager(_ manager: AudioManager, didMoveLeftCropHandleTo percentage: CGFloat) {}
    func audioManager(_ manager: AudioManager, didMoveRightCropHandleTo percentage: CGFloat) {}
    func audioManager(_ manager: AudioManager, didStartCroppingItem item: AudioItem, kind: CropKind) {}
}

extension PlaybackControlsView {
    class func instanceFromNib() -> PlaybackControlsView {
        return UINib(nibName: "PlaybackControlsView", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! PlaybackControlsView
    }
}
