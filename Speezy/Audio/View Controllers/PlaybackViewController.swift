//
//  PlaybackViewController.swift
//  Speezy
//
//  Created by Matt Beaney on 10/07/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import UIKit

class PlaybackViewController: UIViewController {
    
    @IBOutlet weak var imgProfile: UIImageView!
    @IBOutlet weak var playbackSlider: UISlider!
    @IBOutlet weak var lblRemainingTime: UILabel!
    @IBOutlet weak var lblPassedTime: UILabel!
    @IBOutlet weak var playbackButton: UIButton!
    
    @IBOutlet weak var tagsContainer: UIView!
    @IBOutlet weak var commentsContainer: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}
