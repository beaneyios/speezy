//
//  QuickRecordPresenting.swift
//  Speezy
//
//  Created by Matt Beaney on 19/01/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import UIKit

protocol QuickRecordPresenting: QuickRecordViewControllerDelegate {
    func presentQuickRecordDialogue(item: AudioItem)
}

extension QuickRecordPresenting where Self: UIViewController {
    func presentQuickRecordDialogue(item: AudioItem) {
        let storyboard = UIStoryboard(name: "Audio", bundle: nil)
        let quickRecordViewController = storyboard.instantiateViewController(identifier: "quick-record") as! QuickRecordViewController
        
        let newItem = item
        
        let audioManager = AudioManager(item: newItem)
        quickRecordViewController.audioManager = audioManager
        quickRecordViewController.delegate = self
        
        addChild(quickRecordViewController)
        view.addSubview(quickRecordViewController.view)
        
        quickRecordViewController.view.layer.cornerRadius = 10.0
        quickRecordViewController.view.clipsToBounds = true
        quickRecordViewController.view.addShadow()
        
        quickRecordViewController.view.snp.makeConstraints { (make) in
            make.top.equalTo(view.snp.top)
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.bottom.equalTo(view.snp.bottom)
        }
    }
}
