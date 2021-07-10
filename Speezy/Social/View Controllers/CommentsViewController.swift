//
//  CommentsViewController.swift
//  Speezy
//
//  Created by Matt Beaney on 10/07/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import UIKit

class CommentsViewController: UIViewController {
    @IBOutlet weak var sendCommentContainer: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sendCommentContainer.layer.cornerRadius = sendCommentContainer.frame.width / 2.0
        sendCommentContainer.clipsToBounds = true
    }
}
