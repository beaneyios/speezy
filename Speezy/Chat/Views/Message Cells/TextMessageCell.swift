//
//  TextMessageCell.swift
//  Speezy
//
//  Created by Matt Beaney on 10/04/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import UIKit

class TextMessageCell: UICollectionViewCell, NibLoadable {

    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var displayName: UILabel!
    @IBOutlet weak var timestampLabel: UILabel!
    
    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var sendStatusImage: UIImageView!
    @IBOutlet weak var sendStatusImageWidth: NSLayoutConstraint!
    @IBOutlet weak var sendStatusPadding: NSLayoutConstraint!
    @IBOutlet weak var messageContainer: UIView!
    @IBOutlet weak var replyIcon: UIImageView!
    @IBOutlet weak var container: UIView!
    
    @IBOutlet weak var replyBox: UIView!
    @IBOutlet weak var replyBoxHeight: NSLayoutConstraint!
    
    private(set) var message: Message?
    
    var longPressTapped: ((Message) -> Void)?
    var replyTriggered: ((Message) -> Void)?
    var replyTapped: ((MessageReply) -> Void)?
    
    func configure(item: MessageCellModel) {
        self.message = item.message
        
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
                        
        sendStatusImage.alpha = item.tickOpacity
        sendStatusImageWidth.constant = item.tickWidth
        sendStatusPadding.constant = item.tickPadding
                
        let longTap = UILongPressGestureRecognizer(target: self, action: #selector(longPressedCell))
        addGestureRecognizer(longTap)

        configureImage(item: item)
        
        setNeedsLayout()
        layoutIfNeeded()
        profileImage.layer.cornerRadius = profileImage.frame.height / 2.0
        
        let panGestureRecogniser = UIPanGestureRecognizer(target: self, action: #selector(swipePan(sender:)))
        container.addGestureRecognizer(panGestureRecogniser)
        panGestureRecogniser.delegate = self
        
        configureReplyBox(item: item)
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
    
    @objc private func longPressedCell() {
        guard let message = message else {
            return
        }
        
        longPressTapped?(message)
    }
    
    @objc func swipePan(sender: UIPanGestureRecognizer) {
        let translation = sender.translation(in: self)
        let dampenedTranslation = translation.x * 0.7
        
        switch sender.state {
        case .changed:
            if translation.x > 0.0 {
                return
            }
            
            let newTranslation: CGFloat = {
                if abs(dampenedTranslation) > (frame.width / 3.0) {
                    return -(frame.width / 3.0)
                } else {
                    return dampenedTranslation
                }
            }()
            
            if dampenedTranslation < -60.0 && replyIcon.alpha == 0.0 {
                UIView.animate(withDuration: 0.3) {
                    self.replyIcon.alpha = 1.0
                }
            }
            
            container.transform = CGAffineTransform(translationX: newTranslation, y: 0)
        case .ended:
            
            if dampenedTranslation <= -60.0, let message = self.message {
                replyTriggered?(message)
            }
            
            UIView.animate(withDuration: 0.4) {
                self.replyIcon.alpha = 0.0
                self.container.transform = .identity
            }
        default:
            break
        }
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
    
    @objc private func tappedReply() {
        guard let replyMessage = message?.replyTo else {
            return
        }
        
        replyTapped?(replyMessage)
    }
}

extension TextMessageCell: UIGestureRecognizerDelegate {
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
