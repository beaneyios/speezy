//
//  LargeSoundwaveView.swift
//  Speezy
//
//  Created by Matt Beaney on 12/07/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import UIKit
import SnapKit

class LargeSoundwaveView: UIView {
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var timelineContainer: UIView!
    @IBOutlet weak var waveContainer: UIView!
    
    private var wave: AudioVisualizationView!
    private var timelineView: TimelineView!
    
    private let barSpacing: CGFloat = 3.0
    private let barWidth: CGFloat = 3.0
    private var totalSpacePerBar: CGFloat { barSpacing + barWidth }
    
    private var manager: AudioManager?
    private var audioData: AudioData?
    
    private var currentPlaybackTime: TimeInterval {
        manager?.currentPlaybackTime ?? 0.0
    }
    
    func configure(manager: AudioManager) {
        self.manager = manager
        manager.addObserver(self)
        scrollView.delegate = self
        
        let item = manager.item.url
        AudioLevelGenerator.render(fromAudioURL: item, targetSamplesPolicy: .fitToDuration) { (audioData) in
            DispatchQueue.main.async {
                let waveSize = self.waveSize(audioData: audioData)
                self.audioData = audioData
                self.createTimeLine(seconds: audioData.duration, width: waveSize.width)
                self.createAudioVisualisationView(with: audioData.percentageLevels, seconds: audioData.duration, waveSize: waveSize)
            }
        }
    }
    
    private func createTimeLine(seconds: TimeInterval, width: CGFloat) {
        timelineView?.removeFromSuperview()
        timelineView = nil
        
        let timelineView = TimelineView()
        timelineContainer.addSubview(timelineView)
        timelineView.snp.makeConstraints { (maker) in
            maker.bottom.equalTo(timelineContainer)
            maker.trailing.equalTo(timelineContainer)
            maker.leading.equalTo(timelineContainer)
            maker.top.equalTo(timelineContainer)
        }
        
        timelineView.createTimeLine(seconds: seconds, width: width)
        self.timelineView = timelineView
    }
    
    private func waveSize(audioData: AudioData) -> CGSize {
        CGSize(
            width: CGFloat(audioData.percentageLevels.count) * self.totalSpacePerBar,
            height: self.frame.height - 24.0
        )
    }
}

// MARK: View set up
extension LargeSoundwaveView {
    private func createAudioVisualisationView(with levels: [Float], seconds: TimeInterval, waveSize: CGSize) {
        if let wave = self.wave {
            wave.removeFromSuperview()
            self.wave = nil
            scrollView.setContentOffset(CGPoint.zero, animated: true)
        }
        
        let wave = AudioVisualizationView(
            frame: CGRect(
                x: 0,
                y: 24.0,
                width: waveSize.width,
                height: waveSize.height
            )
        )
        
        wave.gradientEndColor = .white
        wave.gradientStartColor = .red
        wave.meteringLevelBarInterItem = self.barSpacing
        wave.meteringLevelBarWidth = self.barWidth
        wave.tintColor = .white
        wave.audioVisualizationMode = .read
        wave.backgroundColor = .clear
        wave.meteringLevels = levels
        wave.alpha = 0.0
        
        scrollView.contentSize = waveSize
        waveContainer.addSubview(wave)
        self.wave = wave
        
        UIView.animate(withDuration: 0.3) {
            wave.alpha = 1.0
        }
    }
}

// MARK: Playback
extension LargeSoundwaveView {
    private func stop() {
        wave.stop()
        scrollView.setContentOffset(.zero, animated: true)
    }
    
    private func advanceScrollViewWithTimer(advanceFactor: TimeInterval) {
        guard let manager = self.manager, let audioData = audioData else {
            return
        }
        
        let waveSize = self.waveSize(audioData: audioData)
        
        if case AudioManager.State.startedPlayback = manager.state {
            let duration = audioData.duration
            let currentTime = currentPlaybackTime
            let currentPercentage = currentTime / duration
            let centerPoint = waveSize.width * CGFloat(currentPercentage)
            
            scrollView.setContentOffset(
                CGPoint(
                    x: centerPoint - (frame.width / 2.0),
                    y: 0.0
                ),
                animated: false
            )
        } else if case AudioManager.State.startedRecording = manager.state {
            scrollView.setContentOffset(
                CGPoint(
                    x: waveSize.width - frame.width,
                    y: 0.0
                ),
                animated: false
            )
        }
    }
}

// MARK: Observer
extension LargeSoundwaveView: AudioManagerObserver {
    func audioPlayer(_ player: AudioManager, progressedWithTime time: TimeInterval) {
        guard let audioData = audioData else {
            return
        }
        
        let duration = audioData.duration
        let currentPercentage = time / duration
        let waveSize = self.waveSize(audioData: audioData)
        let centerPoint = waveSize.width * CGFloat(currentPercentage)
        
        if centerPoint >= center.x {
            advanceScrollViewWithTimer(advanceFactor: 20.0)
        } else {
            scrollView.setContentOffset(.zero, animated: false)
        }
        
        let newPercentage = Float(time) / Float(audioData.duration)
        wave.advanceGradient(percentage: newPercentage)
    }
    
    func audioPlayer(_ player: AudioManager, didStartPlaying item: AudioItem) {
        // no op
    }
    
    func audioPlayer(_ player: AudioManager, didPausePlaybackOf item: AudioItem) {
        // no op
    }
    
    func audioPlayerDidStop(_ player: AudioManager) {
        stop()
    }
    
    func audioPlayer(_ player: AudioManager, didStartCroppingItem item: AudioItem) {
        // no op
    }
    
    func audioPlayer(_ player: AudioManager, didAdjustCropOnItem item: AudioItem) {
        configure(manager: player)
    }
    
    func audioPlayerDidCancelCropping(_ player: AudioManager) {
        configure(manager: player)
    }
    
    func audioPlayer(_ player: AudioManager, didFinishCroppingItem item: AudioItem) {
        configure(manager: player)
    }
    
    func audioPlayerDidStartRecording(_ player: AudioManager) {
        wave.stop()
        wave.reset()
        wave.audioVisualizationMode = .write
        
        guard let audioData = self.audioData else {
            assertionFailure("Audio data shouldn't be nil here")
            return
        }
        
        audioData.percentageLevels.forEach {
            self.wave.add(meteringLevel: $0)
        }
    }
    
    func audioPlayerProcessingRecording(_ player: AudioManager) {
        alpha = 0.5
    }
    
    func audioPlayerDidStopRecording(_ player: AudioManager) {
        alpha = 1.0
        
        manager = player
        wave.reset()
        wave.audioVisualizationMode = .read
        
        guard let audioData = self.audioData else {
            assertionFailure("Audio data shouldn't be nil here")
            return
        }
        
        wave.meteringLevels = audioData.percentageLevels
    }
    
    func audioPlayer(_ player: AudioManager, didRecordBarWithPower decibel: Float, duration: TimeInterval) {
        let previousDuration = audioData?.duration
        audioData = audioData?.addingDBLevel(decibel, addedDuration: duration)
        let newDuration = audioData?.duration
        
        wave.audioVisualizationMode = .write
        
        guard let audioData = audioData, let percentageLevel = audioData.percentageLevels.last else {
            assertionFailure("Somehow audioData is nil.")
            return
        }
        
        let waveSize = self.waveSize(audioData: audioData)
        
        if let previousDuration = previousDuration, let newDuration = newDuration, Int(previousDuration) < Int(newDuration) {
            timelineView.addSecond(
                second: Int(newDuration),
                gap: self.waveSize(audioData: audioData).width / CGFloat(newDuration)
            )
        }
        
        wave.frame.size.width = waveSize.width
        scrollView.contentSize.width = waveSize.width
        wave.add(meteringLevel: percentageLevel)
        advanceScrollViewWithTimer(advanceFactor: 10.0)
    }
}

extension LargeSoundwaveView: UIScrollViewDelegate {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        manager?.pause()
    }
}

extension LargeSoundwaveView {
    class func instanceFromNib() -> LargeSoundwaveView {
        return UINib(nibName: "LargeSoundwaveView", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! LargeSoundwaveView
    }
}
