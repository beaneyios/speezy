//
//  AudioChatItemCell.swift
//  Speezy
//
//  Created by Matt Beaney on 11/01/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import UIKit

class MessageCell: UICollectionViewCell, NibLoadable {
    @IBOutlet weak var slider: CustomSlider!
    
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var displayName: UILabel!
    
    @IBOutlet weak var durationLabel: UILabel!
    
    @IBOutlet weak var timestampLabel: UILabel!
    @IBOutlet weak var sendStatusImage: UIImageView!
    @IBOutlet weak var sendStatusImageWidth: NSLayoutConstraint!
    
    @IBOutlet weak var messageContainer: UIView!
    @IBOutlet weak var messageBackgroundImage: UIImageView!
    
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    var messageDidStartPlaying: ((MessageCell) -> Void)?
    var messageDidStopPlaying: ((MessageCell) -> Void)?
    
    private var audioManager: AudioManager?
    private var message: Message?
        
    func configure(item: MessageCellModel) {
        self.message = item.message
        
        playButton.tintColor = item.playButtonTint
        
        messageLabel.text = item.messageText
        messageLabel.textColor = item.messageTint
        
        profileImage.image = item.profileImage
        
        timestampLabel.text = item.timestampText
        timestampLabel.textColor = item.timestampTint
        
        sendStatusImage.tintColor = item.tickTint
        
        displayName.text = item.displayNameText
        displayName.textColor = item.displayNameTint
        
        messageContainer.layer.maskedCorners = {
            if item.isSender {
                return [
                    .layerMinXMinYCorner,
                    .layerMinXMaxYCorner,
                    .layerMaxXMinYCorner
                ]
            } else {
                return [
                    .layerMinXMinYCorner,
                    .layerMaxXMaxYCorner,
                    .layerMaxXMinYCorner
                ]
            }
        }()
        
        messageContainer.layer.cornerRadius = 30.0
        messageBackgroundImage.image = item.backgroundImage
        
        durationLabel.text = item.durationText
        durationLabel.textColor = item.durationTint
        
        sendStatusImage.alpha = item.tickOpacity
        sendStatusImageWidth.constant = item.tickWidth
        
        slider.thumbColour = item.sliderThumbColour
        slider.minimumTrackTintColor = item.minSliderColour
        slider.maximumTrackTintColor = item.maxSliderColour
        slider.borderColor = item.sliderBorderColor        
        slider.configure()
        
        spinner.isHidden = true
        spinner.color = item.spinnerTint
        
        slider.alpha = 0.6
        slider.isUserInteractionEnabled = false
        
        slider.addTarget(
            self,
            action: #selector(onSliderValChanged(slider:forEvent:)),
            for: .valueChanged
        )
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
    
    @IBAction func didTapPlay(_ sender: Any) {
        guard let message = self.message, let audioId = message.audioId else {
            return
        }
        
        if let audioManager = self.audioManager {
            audioManager.togglePlayback()
            slider.alpha = 1.0
            slider.isUserInteractionEnabled = true
            return
        }
        
        spinner.isHidden = false
        spinner.startAnimating()
        
        playButton.isHidden = true
        CloudAudioManager.fetchAudioClip(at: "audio_clips/\(audioId).m4a") { (result) in
            let item = AudioItem(
                id: audioId,
                path: "\(audioId).m4a",
                title: "",
                date: Date(),
                tags: []
            )
            
            DispatchQueue.main.async {
                switch result {
                case let .success(data):
                    do {
                        try data.write(to: item.withStagingPath().fileUrl)
                        try data.write(to: item.fileUrl)
                        self.audioManager = AudioManager(item: item)
                        self.audioManager?.addPlaybackObserver(self)
                        self.audioManager?.play()
                    } catch {
                        assertionFailure("Errored with error \(error)")
                        // TODO: handle error here.
                    }
                case let .failure(error):
                    assertionFailure("Errored with error \(error)")
                    // TODO: handle failure here.
                }
                
                self.spinner.isHidden = true
                self.spinner.stopAnimating()
                self.playButton.isHidden = false
                self.slider.alpha = 1.0
                self.slider.isUserInteractionEnabled = true
            }
        }
    }
}

extension MessageCell: AudioPlayerObserver {
    func playBackBegan(on item: AudioItem) {
        messageDidStartPlaying?(self)
        playButton.setImage(UIImage(named: "plain-pause-button"), for: .normal)
    }
    
    func playbackPaused(on item: AudioItem) {
        playButton.setImage(UIImage(named: "plain-play-button"), for: .normal)
        
        messageDidStopPlaying?(self)
    }
    
    func playbackStopped(on item: AudioItem) {
        playButton.setImage(UIImage(named: "plain-play-button"), for: .normal)
        durationLabel.text = TimeFormatter.formatTimeMinutesAndSeconds(time: audioManager?.duration ?? 0.0)
        slider.value = 0.0
        
        messageDidStopPlaying?(self)
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
