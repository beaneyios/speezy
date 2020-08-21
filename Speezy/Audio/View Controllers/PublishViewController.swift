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
        
        self.configureImageAttachment()
        self.configureTags()
        self.configureMainSoundWave()
    }
    
    @IBAction func didTapSend(_ sender: Any) {
        
    }
    
    @IBAction func didTapDraft(_ sender: Any) {
        
    }
    
    @IBAction func didTapCameraButton(_ sender: Any) {
        showAttachmentAlert()
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

extension PublishViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    private func configureImageAttachment() {
        imgBtn.startLoading(color: .lightGray)
        imgBtn.imageView?.contentMode = .scaleAspectFill
        audioManager.fetchImageAttachment { (image) in
            DispatchQueue.main.async {
                self.imgBtn.stopLoading()
                self.imgBtn.layer.cornerRadius = 5.0
                guard let image = image else {
                    self.imgBtn.setImage(UIImage(named: "camera-button"), for: .normal)
                    return
                }
                
                self.imgBtn.setImage(image, for: .normal)
            }
        }
    }
    
    private func showAttachmentAlert() {
        let alert = UIAlertController(title: "Image Selection", message: "From where you want to pick this image?", preferredStyle: .actionSheet)
        
        let cameraAction = UIAlertAction(title: "Camera", style: .default) { action in
            self.getImage(fromSourceType: .camera)
        }
        
        let photoAlbumAction = UIAlertAction(title: "Photo Album", style: .default) { action in
            self.getImage(fromSourceType: .photoLibrary)
        }
        
        let clearPhotoAction = UIAlertAction(title: "Remove Photo", style: .destructive) { action in
            self.audioManager.setImageAttachment(nil) {
                DispatchQueue.main.async {
                    self.configureImageAttachment()
                }
            }
        }
        
        alert.addAction(cameraAction)
        alert.addAction(photoAlbumAction)
        alert.addAction(clearPhotoAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }

    private func getImage(fromSourceType sourceType: UIImagePickerController.SourceType) {
        //Check is source type available
        if UIImagePickerController.isSourceTypeAvailable(sourceType) {
            let imagePickerController = UIImagePickerController()
            imagePickerController.delegate = self
            imagePickerController.sourceType = sourceType
            imgBtn.startLoading(color: .lightGray)
            self.present(imagePickerController, animated: true, completion: nil)
        }
    }
    
    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]
    ) {
        dismiss(animated: true) { [weak self] in
            guard let self = self else {
                return
            }
            
            guard let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else {
                return
            }
            
            self.audioManager.setImageAttachment(image) {
                DispatchQueue.main.async {
                    self.configureImageAttachment()
                }
            }
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        imgBtn.stopLoading()
        picker.dismiss(animated: true, completion: nil)
    }
}
