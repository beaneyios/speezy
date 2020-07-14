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
    
    private var audioVisualizationView: AudioVisualizationView!
    
    private let barSpacing: CGFloat = 3.0
    private let barWidth: CGFloat = 3.0
    private var totalSpacePerBar: CGFloat { barSpacing + barWidth }
    
    private var totalTime: TimeInterval = 0.0
    private var currentTime: TimeInterval = 0.0
    private var manager: AudioManager?

    func configure(manager: AudioManager) {
        self.manager = manager
        manager.addObserver(self)
        scrollView.delegate = self
        AudioLevelGenerator.render(
            fromAudioURL: manager.item.url,
            targetSamplesPolicy: .fitToDuration,
            completion: createAudioVisualisationView(with:seconds:)
        )
    }
}

// MARK: View set up
extension LargeSoundwaveView {
    private func createAudioVisualisationView(with levels: [Float], seconds: TimeInterval) {
        DispatchQueue.main.async {
            let audioVisualizationViewSize = CGSize(
                width: CGFloat(levels.count) * self.totalSpacePerBar,
                height: self.frame.height - 24.0
            )
            
            self.createTimeLine(seconds: seconds, width: audioVisualizationViewSize.width)
            
            let audioVisualizationView = AudioVisualizationView(
                frame: CGRect(
                    x: 0,
                    y: 24.0,
                    width: audioVisualizationViewSize.width,
                    height: audioVisualizationViewSize.height
                )
            )
            
            audioVisualizationView.gradientEndColor = .white
            audioVisualizationView.gradientStartColor = .red
            audioVisualizationView.meteringLevelBarInterItem = self.barSpacing
            audioVisualizationView.meteringLevelBarWidth = self.barWidth
            audioVisualizationView.tintColor = .white
            audioVisualizationView.audioVisualizationMode = .read
            audioVisualizationView.backgroundColor = .clear
            audioVisualizationView.meteringLevels = levels
                        
            self.scrollView.contentSize = audioVisualizationViewSize
            self.contentView.addSubview(audioVisualizationView)
            
            self.audioVisualizationView = audioVisualizationView
        }
    }
    
    private func createTimeLine(seconds: TimeInterval, width: CGFloat) {
        totalTime = seconds
        let gap = width / CGFloat(seconds)
        
        DispatchQueue.main.async {
            var previousLabel: UILabel?
            
            (1...Int(seconds)).forEach {
                let label = UILabel()
                label.font = UIFont.systemFont(ofSize: 12.0)
                label.text = "\(self.timeLabel(duration: TimeInterval($0)))"
                label.textColor = .white
                label.alpha = 0.3
                self.contentView.addSubview(label)
                
                if let previousLabel = previousLabel {
                    label.snp.makeConstraints { (maker) in
                        maker.centerX.equalTo(previousLabel.snp.centerX).offset(gap)
                        maker.top.equalTo(self.contentView)
                    }
                } else {
                    label.snp.makeConstraints { (maker) in
                        maker.centerX.equalTo(self.contentView.snp.centerX).offset(gap)
                        maker.top.equalTo(self.contentView)
                    }
                }
                
                previousLabel = label
                
                let verticalLine = UIView()
                verticalLine.backgroundColor = .white
                verticalLine.alpha = 0.2
                self.contentView.addSubview(verticalLine)
                
                verticalLine.snp.makeConstraints { (maker) in
                    maker.top.equalTo(self.contentView.snp.top).offset(24.0)
                    maker.bottom.equalTo(self.contentView.snp.bottom)
                    maker.width.equalTo(1.0)
                    maker.leading.equalTo(label.snp.leading)
                }
            }
        }
    }
    
    private func timeLabel(duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .positional
        formatter.allowedUnits = [ .minute, .second ]
        formatter.zeroFormattingBehavior = [ .pad ]

        return formatter.string(from: duration) ?? "\(duration)"
    }
}

// MARK: Actions
extension LargeSoundwaveView: AudioManagerObserver {
    func audioPlayer(_ player: AudioManager, progressedWithTime time: TimeInterval) {
        if time > 2.0 {
            self.advanceScrollViewWithTimer()
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
    
    private func play() {
        if self.currentTime > 0.0 {
            audioVisualizationView.play(for: totalTime - currentTime)
        } else {
            audioVisualizationView.play(for: totalTime)
        }
    }
    
    private func pause() {
        guard let percentage = audioVisualizationView.currentGradientPercentage, percentage < 100, percentage > 0 else {
            return
        }

        currentTime = totalTime * TimeInterval(percentage)
        audioVisualizationView.pause()
    }
    
    private func stop() {
        currentTime = 0.0
        audioVisualizationView.stop()
        scrollView.setContentOffset(CGPoint(x: 0.0, y: 0.0), animated: true)
    }
    
    private func advanceScrollViewWithTimer() {
        scrollView.setContentOffset(
            CGPoint(
                x: self.scrollView.contentOffset.x + (scrollView.contentSize.width / CGFloat(totalTime * 20.0)),
                y: 0.0
            ),
            animated: false
        )
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
