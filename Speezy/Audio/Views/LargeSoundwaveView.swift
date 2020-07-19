//
//  LargeSoundwaveView.swift
//  Speezy
//
//  Created by Matt Beaney on 12/07/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import UIKit
import SoundWave
import SnapKit

class LargeSoundwaveView: UIView {
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var timelineContainer: UIView!
    @IBOutlet weak var waveContainer: UIView!
    
    private var wave: AudioVisualizationView!
    
    private let barSpacing: CGFloat = 3.0
    private let barWidth: CGFloat = 3.0
    private var totalSpacePerBar: CGFloat { barSpacing + barWidth }
    
    private var manager: AudioManager?
    private var audioData: AudioData?
    
    private var currentPlaybackTime: TimeInterval {
        manager?.currentPlaybackTime ?? 0.0
    }
    
    private var previousLabel: UILabel?

    func configure(manager: AudioManager) {
        self.manager = manager
        manager.addObserver(self)
        scrollView.delegate = self
        
        let item = manager.trimmedItem?.url ?? manager.item.url
        AudioLevelGenerator.render(fromAudioURL: item, targetSamplesPolicy: .fitToDuration) { (audioData) in
            DispatchQueue.main.async {
                let waveSize = self.waveSize(audioData: audioData)
                self.audioData = audioData
                self.createTimeLine(seconds: audioData.duration, width: waveSize.width)
                self.createAudioVisualisationView(with: audioData.percentageLevels, seconds: audioData.duration, waveSize: waveSize)
            }
        }
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
    
    private func createTimeLine(seconds: TimeInterval, width: CGFloat) {
        timelineContainer.subviews.forEach {
            $0.removeFromSuperview()
        }
        
        let gap = width / CGFloat(seconds)
        
        (1...Int(seconds)).forEach {
            self.addSecond(second: $0, gap: gap)
        }
    }
    
    private func addSecond(second: Int, gap: CGFloat) {
        let label = UILabel()
        label.alpha = 0.0
        label.font = UIFont.systemFont(ofSize: 12.0)
        label.text = "\(self.timeLabel(duration: TimeInterval(second)))"
        label.textColor = .white
        label.alpha = 0.3
        timelineContainer.addSubview(label)
        
        if let previousLabel = previousLabel {
            label.snp.makeConstraints { (maker) in
                maker.centerX.equalTo(previousLabel.snp.centerX).offset(gap)
                maker.top.equalTo(contentView)
            }
        } else {
            label.snp.makeConstraints { (maker) in
                maker.centerX.equalTo(contentView.snp.centerX).offset(gap)
                maker.top.equalTo(contentView)
            }
        }
        
        previousLabel = label
        
        let verticalLine = UIView()
        verticalLine.backgroundColor = .white
        verticalLine.alpha = 0.2
        timelineContainer.addSubview(verticalLine)
        
        verticalLine.snp.makeConstraints { (maker) in
            maker.top.equalTo(contentView.snp.top).offset(24.0)
            maker.bottom.equalTo(contentView.snp.bottom)
            maker.width.equalTo(1.0)
            maker.leading.equalTo(label.snp.leading)
        }
        
        UIView.animate(withDuration: 0.3, delay: TimeInterval(second) / 10.0, options: [], animations: {
            label.alpha = 0.3
        }, completion: nil)
    }
    
    private func timeLabel(duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .positional
        formatter.allowedUnits = [ .minute, .second ]
        formatter.zeroFormattingBehavior = [ .pad ]
        return formatter.string(from: duration) ?? "\(duration)"
    }
}

// MARK: Playback
extension LargeSoundwaveView {
    private func play() {
        guard let duration = audioData?.duration else {
            return
        }
        
        if currentPlaybackTime > 0.0 {
            wave.play(for: duration - currentPlaybackTime)
        } else {
            wave.play(for: duration)
        }
    }
    
    private func pause() {
        guard
            let percentage = wave.currentGradientPercentage,
            percentage < 100, percentage > 0
        else {
            return
        }

        wave.pause()
    }
    
    private func stop() {
        wave.stop()
        
        guard let manager = self.manager else {
            return
        }
        
        configure(manager: manager)
    }
    
    private func advanceScrollViewWithTimer(advanceFactor: TimeInterval) {
        guard let duration = audioData?.duration else {
            return
        }
        
        scrollView.setContentOffset(
            CGPoint(
                x: scrollView.contentOffset.x + (scrollView.contentSize.width / CGFloat(duration * advanceFactor)),
                y: 0.0
            ),
            animated: false
        )
    }
}

// MARK: Observer
extension LargeSoundwaveView: AudioManagerObserver {
    func audioPlayer(_ player: AudioManager, progressedWithTime time: TimeInterval) {
        if time > 2.0 {
            self.advanceScrollViewWithTimer(advanceFactor: 20.0)
        }
    }
    
    func audioPlayer(_ player: AudioManager, didStartPlaying item: AudioItem) {
        play()
    }
    
    func audioPlayer(_ player: AudioManager, didPausePlaybackOf item: AudioItem) {
        pause()
    }
    
    func audioPlayerDidStop(_ player: AudioManager) {
        stop()
    }
    
    func audioPlayer(_ player: AudioManager, didCreateTrimmedItem item: AudioItem) {
        configure(manager: player)
    }
    
    func audioPlayerDidCancelTrim(_ player: AudioManager) {
        configure(manager: player)
    }
    
    func audioPlayer(_ player: AudioManager, didApplyTrimmedItem item: AudioItem) {
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
    
    func audioPlayerDidStopRecording(_ player: AudioManager) {
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
            addSecond(second: Int(newDuration), gap: self.waveSize(audioData: audioData).width / CGFloat(newDuration))
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
