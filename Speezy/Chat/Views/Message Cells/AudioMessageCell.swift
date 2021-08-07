//
//  AudioChatItemCell.swift
//  Speezy
//
//  Created by Matt Beaney on 11/01/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import UIKit

class AudioMessageCell: UICollectionViewCell, NibLoadable {
    @IBOutlet weak var slider: CustomSlider!
    
    @IBOutlet weak var container: UIView!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var displayName: UILabel!
    
    @IBOutlet weak var durationLabel: UILabel!
    
    @IBOutlet weak var timestampLabel: UILabel!
    @IBOutlet weak var sendStatusImage: UIImageView!
    @IBOutlet weak var sendStatusImageWidth: NSLayoutConstraint!
    @IBOutlet weak var sendStatusPadding: NSLayoutConstraint!
    @IBOutlet weak var messageContainer: UIView!
    
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var playButtonImage: UIImageView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
        
    @IBOutlet weak var forwardIcon: UIImageView!
    @IBOutlet weak var replyIcon: UIImageView!
    @IBOutlet weak var unplayedNotification: UIView!
    @IBOutlet weak var unplayedNotificationPadding: NSLayoutConstraint!
    
    @IBOutlet weak var replyBox: UIView!
    @IBOutlet weak var replyBoxHeight: NSLayoutConstraint!
    
    @IBOutlet weak var playbackSpeedContainer: UIView!
    @IBOutlet weak var playbackSpeedLabel: UILabel!
    
    var messageDidStartPlaying: ((AudioMessageCell) -> Void)?
    var messageDidStopPlaying: ((AudioMessageCell) -> Void)?
    var longPressTapped: ((Message) -> Void)?
    var replyTriggered: ((Message) -> Void)?
    var replyTapped: ((MessageReply) -> Void)?
    var forwardTriggered: ((Message) -> Void)?
    
    private(set) var audioManager: AudioManager?
    private(set) var message: Message?
            
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
        messageContainer.layer.cornerRadius = 20.0
        
        configurePlayedStatus(item: item)
                
        sendStatusImage.alpha = item.tickOpacity
        sendStatusImageWidth.constant = item.tickWidth
        sendStatusPadding.constant = item.tickPadding
        
        spinner.isHidden = true
        spinner.color = item.spinnerTint
                
        let longTap = UILongPressGestureRecognizer(target: self, action: #selector(longPressedCell))
        addGestureRecognizer(longTap)
        
        configureAudioControls(item: item)
        configureImage(item: item)
        configureReplyBox(item: item)
        
        setNeedsLayout()
        layoutIfNeeded()
        profileImage.layer.cornerRadius = profileImage.frame.height / 2.0
        
        configureSwipeAction()
    }
    
    func configureImage(item: MessageCellModel) {
        item.loadImage { (result) in
            switch result {
            case let .success(image):
                self.profileImage.image = image
            case let .failure(error):
                self.profileImage.image = item.profileImage
            }
        }
    }
    
    func configureTicks(item: MessageCellModel) {
        sendStatusImage.alpha = item.tickOpacity
    }
    
    func configurePlayedStatus(item: MessageCellModel) {
        unplayedNotification.isHidden = !item.unplayed
        unplayedNotification.layer.cornerRadius = 3.5
        unplayedNotification.clipsToBounds = true
        
        if item.message.message == nil {
            unplayedNotificationPadding.constant = 0.0
        } else {
            unplayedNotificationPadding.constant = 8.0
        }
        
        messageContainer.layer.borderWidth = item.borderWidth
        messageContainer.layer.borderColor = item.borderColor.cgColor
    }
    
    private func configureReplyBox(item: MessageCellModel) {
        
        replyBox.subviews.forEach {
            $0.removeFromSuperview()
        }
        
        guard let messageReply = item.message.replyTo else {
            replyBoxHeight.constant = 0.0
            return
        }
        
        replyBoxHeight.constant = 50.0
        
        let replyBox = ReplyMessageEmbedView.createFromNib()
        self.replyBox.addSubview(replyBox)
        replyBox.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }
        
        let viewModel = ReplyMessageEmbedViewModel(
            message: messageReply,
            sender: item.isSender,
            chatterColor: item.color ?? .speezyPurple
        )
        
        replyBox.configure(viewModel: viewModel)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tappedReply))
        replyBox.addGestureRecognizer(tapGesture)
    }
    
    private func configureSwipeAction() {
        let panGestureRecogniser = UIPanGestureRecognizer(target: self, action: #selector(swipePan(sender:)))
        container.addGestureRecognizer(panGestureRecogniser)
        panGestureRecogniser.delegate = self
    }
    
    private func configureAudioControls(item: MessageCellModel) {
        durationLabel.isHidden = false
        slider.isHidden = false
        playButton.isHidden = false
        playButtonImage.isHidden = false
        
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
        
        slider.value = 0.0
        
        playButtonImage.tintColor = item.playButtonTint
        playButtonImage.image = UIImage(named: "plain-play-button")
        playButton.isUserInteractionEnabled = true
        
        playbackSpeedContainer.backgroundColor = .clear
        playbackSpeedContainer.layer.cornerRadius = 8.0
        playbackSpeedContainer.layer.borderWidth = 1.0
        playbackSpeedContainer.layer.borderColor = item.playButtonTint.cgColor
        playbackSpeedLabel.textColor = item.playButtonTint
        playbackSpeedLabel.text = PlaybackSpeed.one.label
    }
    
    @objc private func tappedReply() {
        guard let replyMessage = message?.replyTo else {
            return
        }
        
        replyTapped?(replyMessage)
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
    
    @objc func swipePan(sender: UIPanGestureRecognizer) {
        let translation = sender.translation(in: self)
        let dampenedTranslation = translation.x * 0.7
        
        print(dampenedTranslation)
        
        switch sender.state {
        case .changed:
            
            let newTranslation: CGFloat = {
                if dampenedTranslation < ((frame.width / 3.0) * -1) {
                    return -(frame.width / 3.0)
                } else if dampenedTranslation > (frame.width / 3.0) {
                    return frame.width / 3.0
                } else {
                    return dampenedTranslation
                }
            }()
            
            if dampenedTranslation > 60.0 && forwardIcon.alpha == 0.0 {
                UIView.animate(withDuration: 0.3) {
                    self.forwardIcon.alpha = 1.0
                }
            }
            
            if dampenedTranslation < -60.0 && replyIcon.alpha == 0.0 {
                UIView.animate(withDuration: 0.3) {
                    self.replyIcon.alpha = 1.0
                }
            }
            
            container.transform = CGAffineTransform(translationX: newTranslation, y: 0)
        case .ended:
            
            if dampenedTranslation >= 60.0, let message = self.message {
                forwardTriggered?(message)
                UIView.animate(withDuration: 0.4) {
                    self.forwardIcon.alpha = 0.0
                }
            }
            
            if dampenedTranslation <= -60.0, let message = self.message {
                replyTriggered?(message)
                UIView.animate(withDuration: 0.4) {
                    self.replyIcon.alpha = 0.0
                }
            }
            
            UIView.animate(withDuration: 0.4) {
                self.container.transform = .identity
            }
        default:
            break
        }
    }
    
    @IBAction func didTapPlaybackSpeed(_ sender: Any) {
        let newPlaybackSpeed = audioManager?.adjustPlaybackSpeed() ?? PlaybackSpeed.one
        self.playbackSpeedLabel.text = newPlaybackSpeed.label
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

extension AudioMessageCell: AudioPlayerObserver {
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

extension AudioMessageCell: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
      }

      override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let pan = gestureRecognizer as? UIPanGestureRecognizer else {
            return true
        }
        
        return abs((pan.velocity(in: pan.view)).x) > abs((pan.velocity(in: pan.view)).y)
      }
}
