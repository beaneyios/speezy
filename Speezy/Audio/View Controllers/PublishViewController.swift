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
import SnapKit

protocol PublishViewControllerDelegate: AnyObject {
    func publishViewController(_ viewController: PublishViewController, shouldSendItem item: AudioItem)
    func publishViewController(_ viewController: PublishViewController, didSaveItemToDrafts item: AudioItem)
    func publishViewControllerShouldNavigateHome(_ viewController: PublishViewController)
    func publishViewControllerShouldNavigateBack(_ viewController: PublishViewController)
}

class PublishViewController: UIViewController {
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var playbackContainer: UIView!
    @IBOutlet weak var waveContainer: UIView!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var textViewPlaceholder: UILabel!
    @IBOutlet weak var imgBtn: SpeezyButton!
    @IBOutlet weak var tagsContainer: UIView!
    @IBOutlet weak var titleToggle: UISwitch!
    @IBOutlet weak var imageToggle: UISwitch!
    @IBOutlet weak var tagsToggle: UISwitch!
    @IBOutlet weak var playbackBtn: UIButton!
    @IBOutlet weak var sendBtn: UIButton!
    
    private var tagsView: TagsView?
    private var waveView: PlaybackView!
    private var shareView: ShareViewController!
        
    weak var delegate: PublishViewControllerDelegate?
    
    var audioManager: AudioManager!
    
    lazy var shareController = AudioShareController(parentViewController: self)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSLog("Configuring publish view controller")
        configureAudioManager()
        
        NSLog("Finished configuring manager")
        
        configureSubviews()
        
        NSLog("Finished configuring subviews")
    }
    
    @IBAction func didTapPlay(_ sender: Any) {
        audioManager.togglePlayback()
    }
    
    @IBAction func didTapSend(_ sender: Any) {
        audioManager.save(saveAttachment: true) { (item) in
            DispatchQueue.main.async {
                let shareConfig = ShareConfig(
                    includeTags: self.tagsToggle.isOn,
                    includeTitle: self.titleToggle.isOn,
                    attachment: self.imageToggle.isOn ? self.audioManager.currentImageAttachment : nil
                )
                
                self.shareController.share(
                    self.audioManager.item,
                    config: shareConfig,
                    completion: nil
                )
            }
        }
    }
    
    @IBAction func didTapDraft(_ sender: Any) {
        audioManager.save(saveAttachment: true) { (item) in
            DispatchQueue.main.async {
                self.delegate?.publishViewController(self, didSaveItemToDrafts: item)
                self.delegate?.publishViewControllerShouldNavigateHome(self)
            }
        }
    }
    
    @IBAction func didTapCameraButton(_ sender: Any) {
        showAttachmentAlert()
    }
    
    @IBAction func didTapBack(_ sender: Any) {
        if audioManager.hasUnsavedChanges {
            let alert = UIAlertController(title: "Changes not saved", message: "You have unsaved changes, would you like to save or discard them?", preferredStyle: .actionSheet)
            let saveAction = UIAlertAction(title: "Save", style: .default) { (action) in
                self.audioManager.save(saveAttachment: true) { (item) in
                    DispatchQueue.main.async {
                        self.delegate?.publishViewController(self, didSaveItemToDrafts: item)
                        self.delegate?.publishViewControllerShouldNavigateBack(self)
                    }
                }
            }
            
            let discardAction = UIAlertAction(title: "Discard", style: .destructive) { (action) in
                self.audioManager.discard {
                    self.delegate?.publishViewControllerShouldNavigateBack(self)
                }
            }
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            
            alert.addAction(saveAction)
            alert.addAction(discardAction)
            alert.addAction(cancelAction)
            present(alert, animated: true, completion: nil)
        } else {
            self.delegate?.publishViewControllerShouldNavigateBack(self)
        }
    }
}

extension PublishViewController {
    private func configureSubviews() {
        configureScrollView()
        configureTextView()
        configureImageAttachment()
        configureTags()
        configureMainSoundWave()
        configureSendButtons()
    }
    
    private func configureSendButtons() {
        sendBtn.layer.cornerRadius = 10.0
    }
}

extension PublishViewController: AudioManagerObserver {
    private func configureAudioManager() {
        audioManager.addObserver(self)
    }
    
    func audioManager(_ manager: AudioManager, didStartPlaying item: AudioItem) {
        playbackBtn.setImage(UIImage(named: "pause-button"), for: .normal)
    }
    
    func audioManager(_ manager: AudioManager, didPausePlaybackOf item: AudioItem) {
        playbackBtn.setImage(UIImage(named: "play-button"), for: .normal)
    }
    
    func audioManager(_ manager: AudioManager, didStopPlaying item: AudioItem) {
        playbackBtn.setImage(UIImage(named: "play-button"), for: .normal)
    }
    
    func audioManager(_ manager: AudioManager, progressedWithTime time: TimeInterval, seekActive: Bool) {}
    func audioManager(_ manager: AudioManager, didStartCroppingItem item: AudioItem, kind: CropKind) {}
    func audioManager(_ manager: AudioManager, didAdjustCropOnItem item: AudioItem) {}
    func audioManager(_ manager: AudioManager, didFinishCroppingItem item: AudioItem) {}
    func audioManager(_ manager: AudioManager, didMoveLeftCropHandleTo percentage: CGFloat) {}
    func audioManager(_ manager: AudioManager, didMoveRightCropHandleTo percentage: CGFloat) {}
    func audioManagerDidCancelCropping(_ manager: AudioManager) {}
    func audioManagerDidStartRecording(_ manager: AudioManager) {}
    func audioManager(_ manager: AudioManager, didRecordBarWithPower decibel: Float, stepDuration: TimeInterval, totalDuration: TimeInterval) {}
    func audioManagerProcessingRecording(_ manager: AudioManager) {}
    func audioManagerDidStopRecording(_ manager: AudioManager, maxLimitedReached: Bool) {}
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
    
    func tagsView(_ tagsView: TagsView, didSelectTag tag: Tag) {
        if tag.id == "add_tag" {
            presentAddTag()
        } else {
            presentDeleteTag(tag: tag)
        }
    }
    
    private func presentDeleteTag(tag: Tag) {
        let alert = UIAlertController(title: "Delete Tag", message: "This will remove the tag from this audio", preferredStyle: .alert)
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { (action) in
            self.audioManager.deleteTag(tag: tag)
            self.configureTags()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(deleteAction)
        alert.addAction(cancelAction)
        present(alert, animated: true, completion: nil)
    }
    
    private func presentAddTag() {
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
            self.presentAddTag()
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
        
        playbackContainer.layer.cornerRadius = 10.0
    }
}

extension PublishViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    private func configureImageAttachment() {
        imgBtn.startLoading(color: .lightGray)
        imgBtn.imageView?.contentMode = .scaleAspectFill
        
        let imageApplication: (UIImage?) -> Void = { image in
            self.imgBtn.stopLoading()
            self.imgBtn.layer.cornerRadius = 10.0
            guard let image = image else {
                self.imgBtn.setImage(UIImage(named: "camera-button"), for: .normal)
                return
            }
            
            self.imgBtn.setImage(image, for: .normal)
        }
        
        if let image = audioManager.currentImageAttachment {
            DispatchQueue.main.async {
                imageApplication(image)
            }
        } else {
            audioManager.fetchImageAttachment { (image) in
                DispatchQueue.main.async {
                    imageApplication(image)
                }
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
            self.audioManager.setImageAttachment(nil)
            self.configureImageAttachment()
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
            
            
            self.audioManager.setImageAttachment(image)
            self.configureImageAttachment()
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        imgBtn.stopLoading()
        picker.dismiss(animated: true, completion: nil)
    }
}

extension PublishViewController: UIScrollViewDelegate {
    private func configureScrollView() {
        scrollView.delegate = self
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        view.endEditing(true)
    }
}

extension PublishViewController: UITextViewDelegate {
    private func configureTextView() {
        textView.delegate = self
        textViewPlaceholder.isHidden = audioManager.item.title != ""
        textView.text = audioManager.item.title
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            view.endEditing(true)
            return false
        }
        
        let updatedText = (textView.text as NSString).replacingCharacters(in: range, with: text)

        if updatedText.isEmpty {
            textViewPlaceholder.isHidden = false
        } else {
            textViewPlaceholder.isHidden = true
        }
        
        audioManager.updateTitle(title: updatedText)
        
        return true
    }
}