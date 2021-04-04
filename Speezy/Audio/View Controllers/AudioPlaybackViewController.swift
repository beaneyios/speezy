//
//  AudioPlaybackViewController.swift
//  Speezy
//
//  Created by Matt Beaney on 07/02/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import UIKit

protocol AudioPlaybackViewControllerDelegate: AnyObject {
    func audioPlaybackViewControllerDidTapExit(_ viewController: AudioPlaybackViewController)
    func audioPlaybackViewControllerDidFinish(_ viewController: AudioPlaybackViewController)
}

class AudioPlaybackViewController: UIViewController {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var timerLabel: UILabel!
    
    @IBOutlet weak var playbackContainer: UIView!
    @IBOutlet weak var playBtn: UIButton!
    
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    private var mainWave: PlaybackWaveView?
    
    weak var delegate: AudioPlaybackViewControllerDelegate?
    var audioManager: AudioManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        titleLabel.isHidden = true
        
        spinner.startAnimating()
        audioManager.downloadFile {
            DispatchQueue.main.async {
                self.configureDependencies()
                self.configureSubviews()
                self.spinner.stopAnimating()
                self.spinner.isHidden = true
            }
        }
    }
    
    override func willMove(toParent parent: UIViewController?) {
        if parent == nil {
            delegate?.audioPlaybackViewControllerDidFinish(self)
        }
    }
    
    @IBAction func didTapClose(_ sender: Any) {
        delegate?.audioPlaybackViewControllerDidTapExit(self)
    }
    
    @IBAction func togglePlayback(_ sender: Any) {
        audioManager.togglePlayback()
    }
}

extension AudioPlaybackViewController {
    private func configureDependencies() {
        audioManager.addPlaybackObserver(self)
    }
    
    private func configureSubviews() {
        configureMainSoundWave()
        configureTitle()
    }
    
    private func configureMainSoundWave() {
        mainWave?.removeFromSuperview()
        mainWave = nil
        
        let soundWaveView = PlaybackWaveView.instanceFromNib()
        playbackContainer.addSubview(soundWaveView)
        
        soundWaveView.snp.makeConstraints { (maker) in
            maker.edges.equalTo(self.playbackContainer)
        }
        
        mainWave = soundWaveView
        mainWave?.delegate = self
        
        view.setNeedsLayout()
        view.layoutIfNeeded()
        soundWaveView.configure(manager: audioManager)
    }
    
    private func configureTitle() {
        titleLabel.text = audioManager.item.title
        titleLabel.isHidden = false
    }
}

extension AudioPlaybackViewController: PlaybackWaveViewDelegate {
    func playbackView(
        _ playbackView: PlaybackWaveView,
        didScrollToPosition percentage: CGFloat,
        userInitiated: Bool
    ) {
        if userInitiated {
            let floatPercentage = percentage > 1.0 ? 1.0 : Float(percentage)
            audioManager.seek(to: floatPercentage)
        }
    }
    
    func playbackView(
        _ playbackView: PlaybackWaveView,
        didFinishScrollingOnPosition percentage: CGFloat
    ) {
        
    }
}

extension AudioPlaybackViewController: AudioPlayerObserver {
    func playBackBegan(on item: AudioItem) {
        playBtn.setImage(UIImage(named: "pause-button"), for: .normal)
    }
    
    func playbackPaused(on item: AudioItem) {
        playBtn.setImage(UIImage(named: "play-button"), for: .normal)
    }
    
    func playbackStopped(on item: AudioItem) {
        playBtn.setImage(UIImage(named: "pause-button"), for: .normal)
    }
    
    func playbackProgressed(
        withTime time: TimeInterval,
        seekActive: Bool,
        onItem item: AudioItem,
        startOffset: TimeInterval
    ) {
        timerLabel.text = TimeFormatter.formatTime(time: time)
    }
}
