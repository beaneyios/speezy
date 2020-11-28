//
//  PlaybackView.swift
//  Speezy
//
//  Created by Matt Beaney on 12/07/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import UIKit
import SnapKit

protocol PlaybackWaveViewDelegate: AnyObject {
    func playbackView(_ playbackView: PlaybackWaveView, didScrollToPosition percentage: CGFloat, userInitiated: Bool)
    func playbackView(_ playbackView: PlaybackWaveView, didFinishScrollingOnPosition percentage: CGFloat)
}

class PlaybackWaveView: UIView {
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var keylineContainer: UIView!
    @IBOutlet weak var timelineContainer: UIView!
    @IBOutlet weak var waveContainer: UIView!
    @IBOutlet weak var cropOverlayContainer: UIView!
    
    weak var delegate: PlaybackWaveViewDelegate?
    
    private var waveWidth: Constraint!
    
    private var wave: WaveView!
    private var timelineView: TimelineView!
    private var cropOverlayView: CropOverlayView!
        
    private let barSpacing: CGFloat = 3.0
    private let barWidth: CGFloat = 3.0
    private var totalSpacePerBar: CGFloat { barSpacing + barWidth }
    
    private var manager: AudioManager!
    private var audioData: AudioData?
    
    private var userInitiatedSeeking: Bool = false
    
    private var padding: CGFloat {
        frame.width / 2.0
    }
    
    func configure(manager: AudioManager, scrollable: Bool = true, completion: (() -> Void)? = nil) {
        self.manager = manager
        manager.addPlaybackObserver(self)
        manager.addRecorderObserver(self)
        manager.addCropperObserver(self)
        manager.addCutterObserver(self)
        
        scrollView.isUserInteractionEnabled = scrollable
        
        render(completion: completion)
    }
    
    private func render(completion: (() -> Void)? = nil) {
        scrollView.delegate = self
        AudioLevelGenerator.render(fromAudioItem: manager.item, targetSamplesPolicy: .fitToDuration) { (audioData) in
            DispatchQueue.main.async {
                let line = UIView()
                line.backgroundColor = UIColor(named: "speezy-red")
                line.alpha = 0.6
                
                self.keylineContainer.addSubview(line)
                
                line.snp.makeConstraints { (maker) in
                    maker.height.equalTo(2.0)
                    maker.trailing.equalToSuperview()
                    maker.leading.equalToSuperview()
                    maker.centerY.equalToSuperview()
                    maker.centerX.equalToSuperview()
                }
                
                let waveSize = self.waveSize(audioData: audioData)
                self.audioData = audioData
                self.createTimeLine(seconds: audioData.duration, width: waveSize.width)
                self.createWaveView(with: audioData.percentageLevels, seconds: audioData.duration, waveSize: waveSize)
                completion?()
            }
        }
    }
}

// MARK: VIEW SET UP
extension PlaybackWaveView {
    private func createCropOverlayView(waveSize: CGSize) {
        cropOverlayView?.removeFromSuperview()
        cropOverlayView = nil
        
        let cropOverlayView = CropOverlayView.createFromNib()
        cropOverlayView.alpha = 0.0
        cropOverlayContainer.addSubview(cropOverlayView)
        
        cropOverlayView.snp.makeConstraints { (maker) in
            maker.top.equalToSuperview()
            maker.leading.equalToSuperview().offset(padding)
            maker.bottom.equalToSuperview()
            maker.width.equalTo(waveSize.width)
        }
        
        self.cropOverlayView = cropOverlayView
        
        UIView.animate(withDuration: 0.3) {
            cropOverlayView.alpha = 1.0
        }
    }
    
    private func removeCropOverlayView() {
        UIView.animate(withDuration: 0.3, animations: {
            self.cropOverlayView?.alpha = 0.0
        }) { (finished) in
            self.cropOverlayView?.removeFromSuperview()
            self.cropOverlayView = nil
        }
    }
    
    private func createTimeLine(seconds: TimeInterval, width: CGFloat) {
        timelineView?.removeFromSuperview()
        timelineView = nil
        
        let timelineView = TimelineView()
        timelineView.tag = 1
        timelineContainer.addSubview(timelineView)
        timelineView.snp.makeConstraints { (maker) in
            maker.bottom.equalTo(timelineContainer)
            maker.trailing.equalTo(timelineContainer)
            maker.leading.equalTo(timelineContainer).offset(padding)
            maker.top.equalTo(timelineContainer)
        }
        
        timelineView.createTimeLine(seconds: seconds, width: width)
        self.timelineView = timelineView
    }
    
    private func waveSize(audioData: AudioData) -> CGSize {
        CGSize(
            width: (CGFloat(audioData.percentageLevels.count) * self.totalSpacePerBar),
            height: self.frame.height - 24.0
        )
    }
    
    private func createWaveView(with levels: [Float], seconds: TimeInterval, waveSize: CGSize) {
        if let wave = self.wave {
            wave.removeFromSuperview()
            self.wave = nil
            scrollView.setContentOffset(CGPoint.zero, animated: true)
        }
        
        let wave = WaveView(
            frame: CGRect(
                x: 0,
                y: 24.0,
                width: waveSize.width,
                height: waveSize.height
            )
        )
        
        wave.configure(with: levels)
        wave.backgroundColor = .clear
        wave.alpha = 0.0
        wave.translatesAutoresizingMaskIntoConstraints = false
        
        scrollView.contentSize = waveSize
        waveContainer.addSubview(wave)
        waveContainer.tag = 1234
        self.wave = wave
        
        wave.snp.makeConstraints { (maker) in
            maker.leading.equalToSuperview().offset(padding)
            maker.top.equalToSuperview()
            maker.bottom.equalToSuperview()
            maker.trailing.equalToSuperview().offset(-padding)
            self.waveWidth = maker.width.equalTo(waveSize.width).constraint
        }
        
        UIView.animate(withDuration: 0.3) {
            wave.alpha = 1.0
        }
    }
}

// MARK: SCROLL VIEW HANDLING
extension PlaybackWaveView {
    func seekToLeftCropHandle() {
        let percentage = cropOverlayView.leftHandlePositionPercentage()
        seek(to: Double(percentage))
    }
    
    func seekToRightCropHandle() {
        let percentage = cropOverlayView.rightHandlePositionPercentage()
        seek(to: Double(percentage))
    }
    
    func seek(to percentage: Double) {
        guard let audioData = audioData else {
            return
        }
        
        let time: TimeInterval = {
            if percentage == 0 {
                return 0
            } else {
                return audioData.duration * percentage
            }
        }()
        
        let waveSize = self.waveSize(audioData: audioData)
        advanceScrollViewForPlayback(
            waveSize: waveSize,
            audioData: audioData,
            time: time
        )
    }
    
    private func stop() {
        guard let audioData = self.audioData else {
            return
        }
        
        advanceScrollViewWithTime(time: manager.startOffset, playback: true)
    }
    
    private func advanceScrollViewWithTime(time: TimeInterval, playback: Bool) {
        guard let audioData = audioData else {
            return
        }
        
        let waveSize = self.waveSize(audioData: audioData)
        
        if playback {
            advanceScrollViewForPlayback(
                waveSize: waveSize,
                audioData: audioData,
                time: time
            )
        } else {
            advanceScrollViewForRecording(waveSize: waveSize)
        }
    }
    
    private func advanceScrollViewForPlayback(
        waveSize: CGSize,
        audioData: AudioData,
        time: TimeInterval
    ) {
        let duration = audioData.duration
        let currentTime = time
        let currentPercentage = currentTime / duration
        let centerPoint = waveSize.width * CGFloat(currentPercentage)
        
        scrollView.setContentOffset(
            CGPoint(
                x: centerPoint,
                y: 0.0
            ),
            animated: false
        )
    }
    
    private func advanceScrollViewForRecording(waveSize: CGSize) {
        let waveWidth = waveSize.width
        
        let offset: CGFloat = waveWidth + padding
                    
        scrollView.setContentOffset(
            CGPoint(
                x: offset,
                y: 0.0
            ),
            animated: false
        )
    }
}

// MARK: PLAYBACK LISTENERS
extension PlaybackWaveView: AudioPlayerObserver {
    func playBackBegan(on item: AudioItem) {}
    
    func playbackPaused(on item: AudioItem) {
        
    }
    
    func playbackStopped(on item: AudioItem) {
        stop()
    }
    
    func playbackProgressed(
        withTime time: TimeInterval,
        seekActive: Bool,
        onItem item: AudioItem,
        startOffset: TimeInterval
    ) {
        if seekActive == false {
            print("Start offset \(startOffset)")
            print("Time \(time)")
            let time = time + startOffset
            advanceScrollViewWithTime(time: time, playback: true)
        }
    }
}

// MARK: RECORDING LISTENERS
extension PlaybackWaveView: AudioRecorderObserver {
    func recordingBegan() {
        
    }
    
    func recordedBar(withPower decibel: Float, stepDuration: TimeInterval, totalDuration: TimeInterval) {
        let previousDuration = audioData?.duration
        audioData = audioData?.addingDBLevel(decibel, addedDuration: stepDuration)
        let newDuration = audioData?.duration
        
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
        
        waveWidth.update(offset: waveSize.width)
        wave.add(meteringLevel: percentageLevel)
        advanceScrollViewWithTime(time: 0.0, playback: false)
    }
    
    func recordingProcessing() {
        alpha = 0.5
    }
    
    func recordingStopped(maxLimitedReached: Bool) {
        self.alpha = 1.0
    }
}

// MARK: CROPPING LISTENERS
extension PlaybackWaveView: AudioCropperObserver {
    func croppingStarted(onItem item: AudioItem) {
        guard let audioData = self.audioData else {
            assertionFailure("Somehow audio data is nil")
            return
        }
        
        let waveSize = self.waveSize(audioData: audioData)
        createCropOverlayView(waveSize: waveSize)
    }
    
    func croppingFinished(onItem item: AudioItem) {
        configure(manager: manager)
        removeCropOverlayView()
    }
    
    func leftCropHandle(movedToPercentage percentage: CGFloat) {
        cropOverlayView.changeStart(percentage: percentage)
    }
    
    func rightCropHandle(movedToPercentage percentage: CGFloat) {
        cropOverlayView.changeEnd(percentage: percentage)
    }
    
    func croppingCancelled() {
        removeCropOverlayView()
    }
    
    func cropRangeAdjusted(onItem item: AudioItem) {}
}

extension PlaybackWaveView: AudioCutterObserver {
    func cuttingStarted(onItem item: AudioItem) {
        guard let audioData = self.audioData else {
            assertionFailure("Somehow audio data is nil")
            return
        }
        
        let waveSize = self.waveSize(audioData: audioData)
        createCropOverlayView(waveSize: waveSize)
    }
    
    func cuttingFinished(onItem item: AudioItem) {
        configure(manager: manager)
        removeCropOverlayView()
    }
    
    func cuttingCancelled() {
        removeCropOverlayView()
    }
    
    func cutRangeAdjusted(onItem item: AudioItem) {}
}

extension PlaybackWaveView: UIScrollViewDelegate {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        manager?.pause()
        userInitiatedSeeking = true
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        // It's not going to slide any further, so the scroll view has finished moving.
        if decelerate == false {
            userInitiatedSeeking = false
            let contentOffsetX = scrollView.contentOffset.x
            let contentSizeWidth = scrollView.contentSize.width - frame.size.width
            let percentage = contentOffsetX / contentSizeWidth
            delegate?.playbackView(self, didFinishScrollingOnPosition: percentage)
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        // The scroll view is decelerating as a result of a user swipe (as opposed to a timer change).
        if userInitiatedSeeking {
            userInitiatedSeeking = false
            let contentOffsetX = scrollView.contentOffset.x
            let contentSizeWidth = scrollView.contentSize.width - frame.size.width
            let percentage = contentOffsetX / contentSizeWidth
            delegate?.playbackView(self, didFinishScrollingOnPosition: percentage)
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let contentOffsetX = scrollView.contentOffset.x
        let contentSizeWidth = scrollView.contentSize.width - frame.size.width
        
        let percentage = contentOffsetX / contentSizeWidth
        delegate?.playbackView(
            self,
            didScrollToPosition: percentage,
            userInitiated: userInitiatedSeeking
        )
    }
}

extension PlaybackWaveView {
    class func instanceFromNib() -> PlaybackWaveView {
        return UINib(nibName: "PlaybackWaveView", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! PlaybackWaveView
    }
}
