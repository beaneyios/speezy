//
//  PublishViewController.swift
//  Speezy
//
//  Created by Matt Beaney on 19/08/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import Foundation
import UIKit
import SCLAlertView

class PublishViewController: UIViewController {
    @IBOutlet weak var waveContainer: UIView!
    private var waveView: PlaybackView!
    
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var imgBtn: SpeezyButton!
    
    @IBOutlet weak var tagsContainer: UIView!
    private var tagsView: TagsView?
    
    @IBOutlet weak var titleToggle: UISwitch!
    @IBOutlet weak var imageToggle: UISwitch!
    @IBOutlet weak var tagsToggle: UISwitch!
    
    var audioManager: AudioManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        audioManager.fetchImageAttachment { (image) in
            if let image = image {
                self.imgBtn.setImage(image, for: .normal)
            }
        }
        
        self.configureTags()
        self.configureMainSoundWave()
    }
    
    @IBAction func didTapSend(_ sender: Any) {
        
    }
    
    @IBAction func didTapDraft(_ sender: Any) {
        
    }
}

extension PublishViewController: TagsViewDelegate {
    private func configureTags() {
        tagsView?.removeFromSuperview()
        tagsView = nil
        
        let tagsView = TagsView.createFromNib()
        tagsView.delegate = self
        tagsContainer.addSubview(tagsView)
        
        tagsView.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }
        
        tagsView.configure(
            with: audioManager.item.tags,
            foreColor: UIColor(named: "speezy-purple")!,
            backColor: .clear,
            scrollDirection: .horizontal,
            showAddTag: true
        )

        self.tagsView = tagsView
    }
    
    func tagsViewDidSelectAddTag(_ tagsView: TagsView) {
        
        let appearance = SCLAlertView.SCLAppearance(fieldCornerRadius: 8.0, buttonCornerRadius: 8.0)
        let alert = SCLAlertView(appearance: appearance)
        let textField = alert.addTextField("Add tag")
        textField.layer.cornerRadius = 12.0
        alert.addButton("Add tag") {
            guard let text = textField.text else {
                return
            }
            
            self.audioManager.addTag(title: text)
            self.configureTags()
        }
        
        alert.addButton("Add another") {
            guard let text = textField.text else {
                return
            }
            
            self.audioManager.addTag(title: text)
            self.configureTags()
            self.tagsViewDidSelectAddTag(tagsView)
        }
        
        alert.showEdit(
            "Add Tag",
            subTitle: "Add the title for your tag here. Add multiple tags by separating with a comma (,)",
            closeButtonTitle: "Cancel",
            colorStyle: 0x3B08A0,
            animationStyle: .bottomToTop
        )
    }
}

extension PublishViewController {
    private func configureMainSoundWave() {
        let soundWaveView = PlaybackView.instanceFromNib()
        waveContainer.addSubview(soundWaveView)
        
        soundWaveView.snp.makeConstraints { (maker) in
            maker.edges.equalTo(self.waveContainer)
        }
        
        soundWaveView.configure(manager: audioManager)
        waveView = soundWaveView
    }
}
