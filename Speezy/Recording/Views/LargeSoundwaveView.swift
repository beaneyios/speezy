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
    
    private var timer: Timer?
    private var audioVisualizationView: AudioVisualizationView!
    private var currentPosition: TimeInterval = 0.0
    
    private let spacing: CGFloat = 3.0
    private let width: CGFloat = 3.0
    private var totalSpacePerBar: CGFloat {
        spacing + width
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
        let audioFile = try! AVAudioFile(forReading: url)
        let audioFilePFormat = audioFile.processingFormat
        let audioFileLength = audioFile.length

        let frameSizeToRead = Int(audioFilePFormat.sampleRate / 25)
        let numberOfFrames = Int(audioFileLength) / frameSizeToRead
        
        let dbLevels = AudiowaveRenderer.render(audioContext: context, targetSamples: numberOfFrames)
        
        guard let minLevel = dbLevels.sorted().first else {
            return
        }
        
        let percentageValues = dbLevels.map {
            ($0 - minLevel) / 100
        }
        
        createAudioVisualisationView(with: percentageValues)
    }
    
    private func createAudioVisualisationView(with levels: [Float]) {
        DispatchQueue.main.async {
            let audioVisualizationViewSize = CGSize(
                width: CGFloat(levels.count) * self.totalSpacePerBar,
                height: self.frame.height
            )
            
            let audioVisualizationView = AudioVisualizationView(
                frame: CGRect(
                    x: 0,
                    y: 0,
                    width: audioVisualizationViewSize.width,
                    height: audioVisualizationViewSize.height
                )
            )
            
            audioVisualizationView.gradientEndColor = .white
            audioVisualizationView.gradientStartColor = .red
            audioVisualizationView.meteringLevelBarInterItem = self.spacing
            audioVisualizationView.meteringLevelBarWidth = self.width
            audioVisualizationView.tintColor = .white
            audioVisualizationView.audioVisualizationMode = .read
            audioVisualizationView.backgroundColor = .clear
            audioVisualizationView.meteringLevels = levels
                        
            self.scrollView.contentSize = audioVisualizationViewSize
            self.contentView.addSubview(audioVisualizationView)
            
            self.audioVisualizationView = audioVisualizationView
            self.play()
        }
    }
    
    private func play() {
        audioVisualizationView.play(for: 10.0)
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
                x: self.scrollView.contentOffset.x + (scrollView.contentSize.width / 200.0),
                y: 0.0
            ),
            animated: false
        )
    }
}

extension LargeSoundwaveView: UIScrollViewDelegate {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        guard let percentage = audioVisualizationView.currentGradientPercentage, percentage < 100 else {
            return
        }
        
        currentPosition = 10 * TimeInterval((audioVisualizationView.currentGradientPercentage ?? 1))
        timer?.invalidate()
        audioVisualizationView.pause()
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard let percentage = audioVisualizationView.currentGradientPercentage, percentage < 100 else {
            return
        }
        
        let currentOffset = scrollView.contentSize.width * CGFloat(percentage)
        scrollView.setContentOffset(
            CGPoint(x: currentOffset - (frame.width / 2.0), y: 0.0),
            animated: false
        )
        
        startTimer()
        audioVisualizationView.play(for: 10 - currentPosition)
    }
}

extension LargeSoundwaveView {
    class func instanceFromNib() -> LargeSoundwaveView {
        return UINib(nibName: "LargeSoundwaveView", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! LargeSoundwaveView
    }
}
