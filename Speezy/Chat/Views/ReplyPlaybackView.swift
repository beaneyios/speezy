//
//  ReplyPlaybackView.swift
//  Speezy
//
//  Created by Matt Beaney on 18/04/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import UIKit

class ReplyPlaybackView: UIView, NibLoadable {
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var chatterLabel: UILabel!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var slider: CustomSlider!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var playSpinner: UIActivityIndicatorView!
    
    var cancelAction: (() -> Void)?
    
    private var audioManager: AudioManager?
    private var messageReply: MessageReply?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
//        slider.thumbColour = .white
//        slider.minimumTrackTintColor = .white
//        slider.maximumTrackTintColor = UIColor.white.withAlphaComponent(0.3)
//        slider.borderColor = .white
//        slider.thumbRadius = 12
//        slider.depressedThumbRadius = 15
//        slider.configure()
//        playSpinner.isHidden = true
    }
    
    func configure(reply: MessageReply) {
        messageReply = reply
        messageLabel.text = reply.message
        
//        if let duration = reply.duration {
//            durationLabel.text = TimeFormatter.formatTimeMinutesAndSeconds(time: duration)
//        }
    }
    
    func showLoader() {
        playSpinner.isHidden = false
        playSpinner.startAnimating()
        playButton.isHidden = true
    }
    
    @IBAction func cancelTapped(_ sender: Any) {
        cancelAction?()
    }
    
    @IBAction func playButtonTapped(_ sender: Any) {
        guard let message = self.messageReply, let audioId = message.audioId else {
            return
        }
        
        if let audioManager = self.audioManager {
            audioManager.togglePlayback()
            slider.alpha = 1.0
            slider.isUserInteractionEnabled = true
            return
        }
        
        showLoader()
        
        CloudAudioManager.downloadAudioClip(id: audioId) { (result) in
            DispatchQueue.main.async {
                switch result {
                case let .success(item):
                    do {
                        self.audioManager = AudioManager(item: item)
                        self.audioManager?.addPlaybackObserver(self)
                        self.audioManager?.play()
                    } catch {
                        assertionFailure("Errored with error \(error)")
                        // TODO: handle error here.
                    }
                case let .failure(error):
                    self.playButton.tintColor = .speezyDarkRed
                    self.playButton.setImage(UIImage(named: "error-icon"), for: .normal)
                    self.playButton.isUserInteractionEnabled = false
                }
                
                self.playSpinner.isHidden = true
                self.playSpinner.stopAnimating()
                self.playButton.isHidden = false
                self.slider.alpha = 1.0
                self.slider.isUserInteractionEnabled = true
            }
        }
    }
    
    @objc private func onSliderValChanged(
        slider: UISlider,
        forEvent event: UIEvent
    ) {
        guard let touchEvent = event.allTouches?.first else {
            return
        }
        
        switch touchEvent.phase {
        case UITouch.Phase.began:
            audioManager?.pause()
        case UITouch.Phase.moved:
            audioManager?.seek(to: slider.value)
        case UITouch.Phase.ended:
            audioManager?.play()
        default:
            break
        }
    }
}

// MARK: Playback
extension ReplyPlaybackView: AudioPlayerObserver {
    func playBackBegan(on item: AudioItem) {
        playButton.setImage(
            UIImage(named: "plain-pause-button"),
            for: .normal
        )
    }
    
    func playbackPaused(on item: AudioItem) {
        playButton.setImage(
            UIImage(named: "plain-play-button"),
            for: .normal
        )
    }
    
    func playbackStopped(on item: AudioItem) {
        playButton.setImage(
            UIImage(named: "plain-play-button"),
            for: .normal
        )
        
        durationLabel.text = TimeFormatter.formatTimeMinutesAndSeconds(time: audioManager?.duration ?? 0.0)
        slider.value = 0.0
    }
    
    func playbackProgressed(
        withTime time: TimeInterval,
        seekActive: Bool,
        onItem item: AudioItem,
        startOffset: TimeInterval
    ) {
        
        let percentageTime = time / item.calculatedDuration
        durationLabel.text = TimeFormatter.formatTimeMinutesAndSeconds(time: time)
        
        if seekActive {
            return
        }
        
        slider.value = Float(percentageTime)
    }
}
