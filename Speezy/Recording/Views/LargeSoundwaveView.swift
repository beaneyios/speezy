//
//  LargeSoundwaveView.swift
//  Speezy
//
//  Created by Matt Beaney on 12/07/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import UIKit
import SoundWave
import AVKit
import SnapKit

class LargeSoundwaveView: UIView {
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var button: UIButton!
    private var timer: Timer?
    private var audioVisualizationView: AudioVisualizationView!
    private var currentPosition: TimeInterval = 0.0
    
    private let barSpacing: CGFloat = 3.0
    private let barWidth: CGFloat = 3.0
    private var totalSpacePerBar: CGFloat { barSpacing + barWidth }
    
    private var time: TimeInterval = 0.0
    
    @IBAction func play(_ sender: Any) {
        self.play()
    }
    
    func configure(with url: URL) {
        scrollView.delegate = self
        AudioContext.load(fromAudioURL: url) { (context) in
            guard let context = context else {
                return
            }
            
            self.configure(with: context, url: url)
        }
    }
    
    private func configure(with context: AudioContext, url: URL) {
        guard let audioFile = try? AVAudioFile(forReading: url) else {
            assertionFailure("Couldn't load URL \(url.absoluteString)")
            return
        }
        
        let audioAsset = AVAsset(url: url)
        
        let audioFilePFormat = audioFile.processingFormat
        let audioFileLength = audioFile.length

        let frameSizeToRead = Int(audioFilePFormat.sampleRate / 10)
        let numberOfFrames = Int(audioFileLength) / frameSizeToRead
        
        let dbLevels = AudiowaveRenderer.render(audioContext: context, targetSamples: numberOfFrames)
        
        guard let minLevel = dbLevels.sorted().first else {
            return
        }
        
        let percentageValues = dbLevels.map {
            ($0 - minLevel) / 110
        }
        
        createAudioVisualisationView(with: percentageValues, asset: audioAsset)
    }
    
    private func createAudioVisualisationView(with levels: [Float], asset: AVAsset) {
        DispatchQueue.main.async {
            let audioVisualizationViewSize = CGSize(
                width: CGFloat(levels.count) * self.totalSpacePerBar,
                height: self.frame.height - 24.0
            )
            
            self.createTimeLine(asset: asset, width: audioVisualizationViewSize.width)
            
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
            self.contentView.bringSubviewToFront(self.button)
        }
    }
    
    private func createTimeLine(asset: AVAsset, width: CGFloat) {
        let duration = asset.duration
        let seconds = TimeInterval(CMTimeGetSeconds(duration))
        time = seconds
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
    
    private func play() {
        audioVisualizationView.play(for: time)
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) {
            self.startTimer()
        }
    }
    
    private func startTimer() {
        self.timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { (timer) in
            let scrollView: UIScrollView = self.scrollView
            if scrollView.contentOffset.x >= (scrollView.contentSize.width - self.frame.width) {
                self.timer?.invalidate()
                return
            }
            
            self.advanceScrollViewWithTimer()
        }
    }
    
    private func advanceScrollViewWithTimer() {
        scrollView.setContentOffset(
            CGPoint(
                x: self.scrollView.contentOffset.x + (scrollView.contentSize.width / CGFloat(time * 20.0)),
                y: 0.0
            ),
            animated: false
        )
    }
    
    private func timeLabel(duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .positional
        formatter.allowedUnits = [ .minute, .second ]
        formatter.zeroFormattingBehavior = [ .pad ]

        return formatter.string(from: duration) ?? "\(duration)"
    }
}

extension LargeSoundwaveView: UIScrollViewDelegate {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
//        guard let percentage = audioVisualizationView.currentGradientPercentage, percentage < 100, percentage > 0 else {
//            return
//        }
//
//        currentPosition = 10 * TimeInterval((audioVisualizationView.currentGradientPercentage ?? 1))
//        timer?.invalidate()
//        audioVisualizationView.pause()
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
//        guard let percentage = audioVisualizationView.currentGradientPercentage, percentage < 100 else {
//            return
//        }
//
//        let currentOffset = scrollView.contentSize.width * CGFloat(percentage)
//        scrollView.setContentOffset(
//            CGPoint(x: currentOffset - (frame.width / 2.0), y: 0.0),
//            animated: false
//        )
//
//        startTimer()
//        audioVisualizationView.play(for: 10 - currentPosition)
    }
}

extension LargeSoundwaveView {
    class func instanceFromNib() -> LargeSoundwaveView {
        return UINib(nibName: "LargeSoundwaveView", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! LargeSoundwaveView
    }
}
