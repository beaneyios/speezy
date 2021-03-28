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
    
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var playButtonImage: UIImageView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    @IBOutlet weak var sliderHeight: NSLayoutConstraint!
    
        
    var messageDidStartPlaying: ((MessageCell) -> Void)?
    var messageDidStopPlaying: ((MessageCell) -> Void)?
    var longPressTapped: ((Message) -> Void)?
    
    private(set) var audioManager: AudioManager?
    private var message: Message?
        
    func configure(item: MessageCellModel) {
        self.message = item.message
        self.audioManager = nil
        
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
        
        messageContainer.backgroundColor = item.backgroundColor
        messageContainer.layer.cornerRadius = 30.0
                
        sendStatusImage.alpha = item.tickOpacity
        sendStatusImageWidth.constant = item.tickWidth
        
        spinner.isHidden = true
        spinner.color = item.spinnerTint
                
        let longTap = UILongPressGestureRecognizer(target: self, action: #selector(longPressedCell))
        addGestureRecognizer(longTap)
        
        configureAudioControls(item: item)
    }
    
    func configureTicks(item: MessageCellModel) {
        sendStatusImage.alpha = item.tickOpacity
    }
    
    private func configureAudioControls(item: MessageCellModel) {
        if !item.hasAudio {
            sliderHeight.constant = 0.0
            durationLabel.isHidden = true
            slider.isHidden = true
            playButton.isHidden = true
            playButtonImage.isHidden = true
            return
        } else {
            sliderHeight.constant = 50.0
            durationLabel.isHidden = false
            slider.isHidden = false
            playButton.isHidden = false
            playButtonImage.isHidden = false
        }
        
        durationLabel.text = item.durationText
        durationLabel.textColor = item.durationTint
        
        slider.thumbColour = item.sliderThumbColour
        slider.minimumTrackTintColor = item.minSliderColour
        slider.maximumTrackTintColor = item.maxSliderColour
        slider.borderColor = item.sliderBorderColor
        slider.configure()
        
        slider.alpha = 0.6
        slider.isUserInteractionEnabled = false
        
        slider.addTarget(
            self,
            action: #selector(onSliderValChanged(slider:forEvent:)),
            for: .valueChanged
        )
        
        playButtonImage.tintColor = item.playButtonTint
        playButtonImage.image = UIImage(named: "plain-play-button")
        playButton.isUserInteractionEnabled = true
    }
    
    @objc private func longPressedCell() {
        guard let message = message else {
            return
        }
        
        longPressTapped?(message)
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
        
        playButtonImage.isHidden = true
        
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
                    self.playButtonImage.tintColor = .speezyDarkRed
                    self.playButtonImage.image = UIImage(named: "error-icon")
                    self.playButton.isUserInteractionEnabled = false
                }
                
                self.spinner.isHidden = true
                self.spinner.stopAnimating()
                self.playButtonImage.isHidden = false
                self.slider.alpha = 1.0
                self.slider.isUserInteractionEnabled = true
            }
        }
    }
}

extension MessageCell: AudioPlayerObserver {
    func playBackBegan(on item: AudioItem) {
        messageDidStartPlaying?(self)
        playButtonImage.image = UIImage(named: "plain-pause-button")
    }
    
    func playbackPaused(on item: AudioItem) {
        playButtonImage.image = UIImage(named: "plain-play-button")
        messageDidStopPlaying?(self)
    }
    
    func playbackStopped(on item: AudioItem) {
        playButtonImage.image = UIImage(named: "plain-play-button")
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
