//
//  ChatItem.swift
//  Speezy
//
//  Created by Matt Beaney on 11/01/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import UIKit
import AFDateHelper
import FirebaseStorage

class MessageCellModel: Identifiable {
    var message: Message
    var chat: Chat
    var chatters: [Chatter]
    var currentUserId: String
    var isFavourite: Bool
    var color: UIColor?
    
    private var downloadTask: StorageDownloadTask?
    
    var id: String {
        message.id
    }
    
    init(
        message: Message,
        chat: Chat,
        chatters: [Chatter],
        currentUserId: String,
        isFavourite: Bool,
        color: UIColor?
    ) {
        self.message = message
        self.chat = chat
        self.chatters = chatters
        self.currentUserId = currentUserId
        self.isFavourite = isFavourite
        self.color = color
    }
    
    func loadImage(
        completion: @escaping (StorageFetchResult<UIImage>) -> Void
    ) {
        downloadTask?.cancel()
        downloadTask = ProfileImageFetcher().fetchImage(
            id: message.chatter.id,
            completion: completion
        )
    }
}

extension MessageCellModel {
    var isSender: Bool {
        message.chatter.id == currentUserId
    }
    
    var received: Bool? {
        isSender ? message.readBy.count == chatters.count : nil
    }
}

extension MessageCellModel {
    var hasAudio: Bool {
        message.audioId != nil
    }
    
    var favouriteImage: UIImage? {
        isFavourite ? UIImage(named: "favourite-button-filled") : UIImage(named: "favourite-button")
    }
    
    var favouriteTint: UIColor {
        isSender ? .chatBubbleOther : .speezyPurple
    }
    
    var backgroundColor: UIColor {
        isSender ? .speezyPurple : .chatBubbleOther
    }
    
    // Duration
    var durationText: String? {
        guard let duration = message.duration else {
            return nil
        }
        
        return duration.formattedString
    }
    
    var durationTint: UIColor {
        isSender ? .white : .speezyPurple
    }
    
    // User info
    var profileImage: UIImage? {
        if isSender { return nil }
        
        if let character = message.chatter.displayName.first {
            return SpeezyProfileViewGenerator.generateProfileImage(
                character: String(character),
                color: color
            )
        }
        
        return UIImage(named: "account-btn")
    }
    
    var displayNameText: String? {
        isSender ? "" : message.chatter.displayName
    }
    
    var displayNameTint: UIColor {
        isSender ? .white : .speezyPurple
    }
    
    // Timestamp
    var timestampText: String {
        return message.sent.relativeTimeString
    }
    
    var timestampTint: UIColor {
        isSender ? .white : .speezyPurple
    }
    
    var playButtonTint: UIColor {
        isSender ? .white : .speezyPurple
    }
    
    var spinnerTint: UIColor {
        isSender ? .white : .speezyPurple
    }
    
    // Message
    var messageText: String? {
        message.message
    }
    
    var messageTint: UIColor {
        isSender ? .white : .black
    }
    
    //Background
    var backgroundImage: UIImage? {
        isSender ? UIImage(named: "gradient-background") : nil
    }
    
    // Ticks
    var tickTint: UIColor? {
        guard let received = self.received else {
            return nil
        }
        
        let receivedTint = UIColor.speezyPurple
        let notReceivedTint = UIColor.speezyDarkGrey
        return received ? receivedTint : notReceivedTint
    }
    
    var tickOpacity: CGFloat {
        guard let received = received else {
            return 0.0
        }

        return received ? 1.0 : 0.6
    }
    
    var tickWidth: CGFloat {
        isSender ? 15.0 : 0.0
    }
    
    var tickPadding: CGFloat {
        isSender ? 4.0 : 0.0
    }
    
    // Slider
    var minSliderColour: UIColor {
        isSender ? .white : .speezyPurple
    }
    
    var maxSliderColour: UIColor {
        minSliderColour.withAlphaComponent(0.3)
    }
    
    var sliderThumbColour: UIColor {
        isSender ? .white : .speezyPurple
    }
    
    var sliderBorderColor: UIColor {
        isSender ? .white : .speezyPurple
    }
}

extension Array where Element == MessageCellModel {
    func contains(message: Message) -> Bool {
        contains {
            $0.message == message
        }
    }
}
