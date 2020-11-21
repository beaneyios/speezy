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
    func playbackView(_ playbackView: PlaybackWaveView, didScrollToPosition percentage: CGFloat)
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
    
    func configure(manager: AudioManager) {
        self.manager = manager
        manager.addPlaybackObserver(self)
        manager.addRecorderObserver(self)
        manager.addCropperObserver(self)
        
        render()
    }
    
    override func layoutSubviews() {
        scrollView.contentInset = UIEdgeInsets(top: 0, left: scrollView.frame.width / 2.0, bottom: 0, right: 0)
    }
    
    private func render() {
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
            maker.leading.equalToSuperview()
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
            width: (CGFloat(audioData.percentageLevels.count) * self.totalSpacePerBar) + (scrollView.frame.width / 2.0),
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
        
        scrollView.contentSize = waveSize
        waveContainer.addSubview(wave)
        self.wave = wave
        
        wave.snp.makeConstraints { (maker) in
            maker.leading.equalToSuperview()
            maker.top.equalToSuperview()
            maker.bottom.equalToSuperview()
            
            maker.trailing.lessThanOrEqualToSuperview()
            self.waveWidth = maker.width.equalTo(waveSize.width).constraint
        }
        
        UIView.animate(withDuration: 0.3) {
            wave.alpha = 1.0
        }
    }
}

// MARK: SCROLL VIEW HANDLING
extension PlaybackWaveView {
    private func stop() {
//        wave.stop()
        scrollView.setContentOffset(.zero, animated: true)
    }
    
    private func advanceScrollViewWithTimer(timeOffset: TimeInterval, playback: Bool) {
        guard let audioData = audioData else {
            return
        }
        
        let waveSize = self.waveSize(audioData: audioData)
        
        if playback {
            advanceScrollViewForPlayback(
                waveSize: waveSize,
                audioData: audioData,
                time: timeOffset
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
                x: centerPoint - (frame.width / 2.0),
                y: 0.0
            ),
            animated: false
        )
    }
    
    private func advanceScrollViewForRecording(waveSize: CGSize) {
        let waveWidth = waveSize.width
        
        let offset: CGFloat = {
            if waveWidth < frame.width {
                return 0.0
            } else {
                return waveWidth - frame.width
            }
        }()
                    
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
            let time = time + startOffset
            advanceScrollViewWithTimer(timeOffset: time, playback: true)
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
        advanceScrollViewWithTimer(timeOffset: 0.0, playback: false)
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
    func croppingStarted(onItem item: AudioItem, kind: CropKind) {
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
        guard let audioData = self.audioData else {
            assertionFailure("Somehow audio data is nil")
            return
        }
        
        cropOverlayView.changeStart(percentage: percentage)
        
        let waveWidth = waveSize(audioData: audioData).width
        if waveWidth < frame.width {
            return
        }
                
        let scrollPosition = CGPoint(x: (waveWidth * percentage) - 32.0, y: 0.0)
        scrollView.setContentOffset(scrollPosition, animated: false)
    }
    
    func rightCropHandle(movedToPercentage percentage: CGFloat) {
        guard let audioData = self.audioData else {
            assertionFailure("Somehow audio data is nil")
            return
        }
        
        cropOverlayView.changeEnd(percentage: percentage)
        
        let waveWidth = waveSize(audioData: audioData).width
        if waveWidth < frame.width {
            return
        }
        
        let scrollPosition = CGPoint(x: (waveWidth * percentage) - frame.width + 32.0, y: 0.0)
        scrollView.setContentOffset(scrollPosition, animated: false)
    }
    
    func croppingCancelled() {
        removeCropOverlayView()
    }
    
    func cropRangeAdjusted(onItem item: AudioItem) {}
}

extension PlaybackWaveView: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let contentOffsetX = scrollView.contentOffset.x + (scrollView.frame.width / 2.0)
        let contentSizeWidth = scrollView.contentSize.width
        let percentage = contentOffsetX / contentSizeWidth
        
        print(percentage)
        
        if scrollView.isTracking {
            delegate?.playbackView(self, didScrollToPosition: percentage)
        }
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        manager?.pause()
    }
}

extension PlaybackWaveView {
    class func instanceFromNib() -> PlaybackWaveView {
        return UINib(nibName: "PlaybackWaveView", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! PlaybackWaveView
    }
}
