//
//  ChatViewModel.swift
//  Speezy
//
//  Created by Matt Beaney on 14/01/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import UIKit

class ChatViewModel {
    enum Change {
        case loaded
        case itemInserted(ChatItemCellModel)
    }
    
    typealias ChangeBlock = (Change) -> Void
    var didChange: ChangeBlock?
    private(set) var items = [ChatItemCellModel]()
    
    func listenForData() {
        items = [
            ChatItemCellModel(
                displayName: "James",
                profileImage: UIImage(named: ""),
                timeStamp: "10:11 pm",
                isSender: false,
                received: nil,
                message: "Test message",
                audioUrl: nil,
                attachmentUrl: nil,
                duration: 15.0
            ),
            ChatItemCellModel(
                displayName: "Matt",
                profileImage: UIImage(named: ""),
                timeStamp: "10:15 pm",
                isSender: true,
                received: false,
                message: "Test message",
                audioUrl: nil,
                attachmentUrl: nil,
                duration: 10.0
            ),
            ChatItemCellModel(
                displayName: "James",
                profileImage: UIImage(named: ""),
                timeStamp: "10:11 pm",
                isSender: false,
                received: nil,
                message: "Test message",
                audioUrl: nil,
                attachmentUrl: nil,
                duration: 15.0
            ),
            ChatItemCellModel(
                displayName: "James",
                profileImage: UIImage(named: ""),
                timeStamp: "10:11 pm",
                isSender: false,
                received: nil,
                message: "Test message",
                audioUrl: nil,
                attachmentUrl: nil,
                duration: 15.0
            ),
            ChatItemCellModel(
                displayName: "James",
                profileImage: UIImage(named: ""),
                timeStamp: "10:11 pm",
                isSender: false,
                received: nil,
                message: "Test message",
                audioUrl: nil,
                attachmentUrl: nil,
                duration: 15.0
            ),
            ChatItemCellModel(
                displayName: "James",
                profileImage: UIImage(named: ""),
                timeStamp: "10:11 pm",
                isSender: false,
                received: nil,
                message: "Test message",
                audioUrl: nil,
                attachmentUrl: nil,
                duration: 15.0
            ),
            ChatItemCellModel(
                displayName: "James",
                profileImage: UIImage(named: ""),
                timeStamp: "10:11 pm",
                isSender: false,
                received: nil,
                message: "Test message",
                audioUrl: nil,
                attachmentUrl: nil,
                duration: 15.0
            ),
            ChatItemCellModel(
                displayName: "James",
                profileImage: UIImage(named: ""),
                timeStamp: "10:11 pm",
                isSender: false,
                received: nil,
                message: "Test message",
                audioUrl: nil,
                attachmentUrl: nil,
                duration: 15.0
            ),
            ChatItemCellModel(
                displayName: "James",
                profileImage: UIImage(named: ""),
                timeStamp: "10:11 pm",
                isSender: false,
                received: nil,
                message: "Test message",
                audioUrl: nil,
                attachmentUrl: nil,
                duration: 15.0
            ),
            ChatItemCellModel(
                displayName: "James",
                profileImage: UIImage(named: ""),
                timeStamp: "10:11 pm",
                isSender: false,
                received: nil,
                message: "Test message",
                audioUrl: nil,
                attachmentUrl: nil,
                duration: 15.0
            ),

        ]
        
        didChange?(.loaded)
    }
    
    func addChatItem(you: Bool) {
        let newChatItem = ChatItemCellModel(
            displayName: "James",
            profileImage: UIImage(named: ""),
            timeStamp: "10:11 pm",
            isSender: you,
            received: you ? true : nil,
            message: "Test message",
            audioUrl: nil,
            attachmentUrl: nil,
            duration: 15.0
        )
        
        items.insert(newChatItem, at: 0)
        didChange?(.itemInserted(newChatItem))
    }
}
