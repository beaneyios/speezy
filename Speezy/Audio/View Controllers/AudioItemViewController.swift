//
// AudioItemViewController.swift
//  Speezy
//
//  Created by Matt Beaney on 27/05/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import UIKit
import SnapKit
import SCLAlertView
import Hero

protocol AudioItemViewControllerDelegate: AnyObject {
    func audioItemViewController(_ viewController: AudioItemViewController, didSaveItem item: AudioItem)
    func audioItemViewControllerShouldPop(_ viewController: AudioItemViewController)
}

class AudioItemViewController: UIViewController, AudioShareable {
    
    @IBOutlet var recordHidables: [UIButton]!
    @IBOutlet var playbackHidables: [UIButton]!
    @IBOutlet var cropHidables: [UIButton]!
    
    @IBOutlet weak var btnCut: UIButton!
    @IBOutlet weak var btnRecord: SpeezyButton!
    @IBOutlet weak var btnCrop: UIButton!
    @IBOutlet weak var btnShare: UIButton!
    @IBOutlet weak var btnTitle: UIButton!
    @IBOutlet weak var btnTitle2: UIButton!
    @IBOutlet weak var btnCamera: SpeezyButton!
    
    @IBOutlet weak var bgGradient: UIImageView!
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var recordContainer: UIView!
    @IBOutlet weak var mainWaveContainer: UIView!
    @IBOutlet weak var cropContainer: UIView!
    @IBOutlet weak var cropContainerHeight: NSLayoutConstraint!
    @IBOutlet weak var tagContainer: UIView!
    @IBOutlet weak var playbackControlsContainer: UIView!
    
    @IBOutlet weak var lblTimer: UILabel!
    @IBOutlet weak var btnDone: UIButton!
    
    weak var delegate: AudioItemViewControllerDelegate?
    
    private var playbackControlsView: PlaybackControlsView?
    private var mainWave: PlaybackView?
    private var cropView: CropView?
    private var tagsView: TagsView?
    
    var shareAlert: SCLAlertView?
    var documentInteractionController: UIDocumentInteractionController?
    
    var audioManager: AudioManager!
                
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureAudioManager()
        configureMainSoundWave()
        configurePlaybackControls()
        configureTitle()
        configureTags()
        configureImageAttachment()
        hideCropView(animated: false)
        
        hero.isEnabled = true
        btnRecord.hero.id = "record"
        
        let presenting = HeroDefaultAnimationType.zoom
        let dismissing = HeroDefaultAnimationType.zoomOut
        hero.modalAnimationType = .selectBy(presenting: presenting, dismissing: dismissing)
    }
    
    @IBAction func chooseTitle(_ sender: Any) {
        chooseTitle()
    }
    
    @IBAction func close(_ sender: Any) {
        delegate?.audioItemViewControllerShouldPop(self)
    }
    
    @IBAction func toggleRecording(_ sender: Any) {
        audioManager.toggleRecording()
    }
    
    @IBAction func toggleCrop(_ sender: Any) {
        audioManager.toggleCrop()
    }
    
    @IBAction func toggleCut(_ sender: Any) {
        
    }
    
    @IBAction func attachPhoto(_ sender: Any) {
        showAttachmentAlert()
    }
    
    @IBAction func share(_ sender: Any) {
        if audioManager.hasRecorded == false {
            let alert = SCLAlertView()
            alert.showError("No recording found", subTitle: "You haven't recorded anything! Tap the record button to get started", closeButtonTitle: "OK")
            return
        }
        
        btnShare.disable()
        share(item: audioManager.item, attachmentImage: audioManager.currentImageAttachment) {
            DispatchQueue.main.async {
                self.btnShare.enable()
            }
        }
    }
}

// MARK: Configuration
extension AudioItemViewController {
    private func configureAudioManager() {
        audioManager.addObserver(self)
    }
    
    private func configurePlaybackControls() {
        let playbackControlsView = PlaybackControlsView.instanceFromNib()
        playbackControlsView.configure(with: audioManager)
        playbackControlsContainer.addSubview(playbackControlsView)
        playbackControlsView.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }
    }
    
    private func configureMainSoundWave() {
        let soundWaveView = PlaybackView.instanceFromNib()
        mainWaveContainer.addSubview(soundWaveView)
        
        soundWaveView.snp.makeConstraints { (maker) in
            maker.edges.equalTo(self.mainWaveContainer)
        }
        
        soundWaveView.configure(manager: audioManager)
        mainWave = soundWaveView
    }
    
    private func configureTitle() {
        btnTitle.setTitle(audioManager.item.title, for: .normal)
    }
    
    private func configureImageAttachment() {
        btnCamera.startLoading()
        btnCamera.imageView?.contentMode = .scaleAspectFill
        audioManager.fetchImageAttachment { (image) in
            DispatchQueue.main.async {
                self.btnCamera.stopLoading()
                self.btnCamera.layer.cornerRadius = self.btnCamera.frame.width / 2.0
                guard let image = image else {
                    self.btnCamera.setImage(UIImage(named: "camera-button"), for: .normal)
                    return
                }
                
                self.btnCamera.setImage(image, for: .normal)
            }
        }
    }
    
    private func configureTags() {
        tagsView?.removeFromSuperview()
        tagsView = nil
        
        let tagsView = TagsView.createFromNib()
        tagsView.delegate = self
        tagContainer.addSubview(tagsView)
        
        tagsView.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }
        
        tagsView.configure(
            with: audioManager.item.tags,
            foreColor: .white,
            backColor: .clear,
            scrollDirection: .vertical,
            showAddTag: true
        )

        self.tagsView = tagsView
    }
}

// MARK: Actions
extension AudioItemViewController {
    private func chooseTitle() {
        let appearance = SCLAlertView.SCLAppearance(fieldCornerRadius: 8.0, buttonCornerRadius: 8.0)
        let alert = SCLAlertView(appearance: appearance)
        let textField = alert.addTextField("Add a title")
        textField.layer.cornerRadius = 12.0
        alert.addButton("Add") {
            guard let text = textField.text else {
                return
            }
            
            self.audioManager.updateTitle(title: text)
            self.configureTitle()
            self.delegate?.audioItemViewController(self, didSaveItem: self.audioManager.item)
        }
        
        alert.showEdit(
            "Title",
            subTitle: "Add the title for your audio file here",
            closeButtonTitle: "Cancel",
            colorStyle: 0x3B08A0,
            animationStyle: .topToBottom
        )
    }
    
    private func showCropView() {
        btnCrop.setImage(UIImage(named: "crop-button-selected"), for: .normal)
        
        cropHidables.forEach {
            $0.disable()
        }
        
        cropContainerHeight.constant = 100.0
        UIView.animate(withDuration: 0.4, animations: {
            self.view.layoutIfNeeded()
            self.cropContainer.alpha = 1.0
        }) { (finished) in
            let cropView = CropView.instanceFromNib()
            cropView.alpha = 0.0
            self.cropContainer.addSubview(cropView)
            
            cropView.snp.makeConstraints { (maker) in
                maker.edges.equalTo(self.cropContainer)
            }
            
            self.cropView = cropView
            cropView.configure(manager: self.audioManager)
            
            UIView.animate(withDuration: 0.3) {
                cropView.alpha = 1.0
            }
            
            self.scrollView.setContentOffset(
                CGPoint(x: 0, y: 100.0),
                animated: true
            )
        }
    }
    
    private func hideCropView(animated: Bool = true) {
        guard animated else {
            cropContainerHeight.constant = 0.0
            cropContainer.alpha = 0.0
            return
        }
        
        btnCrop.setImage(UIImage(named: "crop-button"), for: .normal)
        
        cropHidables.forEach {
            $0.enable()
        }
        
        UIView.animate(withDuration: 0.3, animations: {
            self.cropContainer.alpha = 0.0
        }) { (finished) in
            self.cropView?.removeFromSuperview()
            self.cropView = nil
            self.cropContainerHeight.constant = 0.0
            UIView.animate(withDuration: 0.3, animations: {
                self.view.layoutIfNeeded()
            })
        }
    }
}

// MARK: Tags view delegate
extension AudioItemViewController: TagsViewDelegate {
    func tagsViewDidSelectAddTag(_ tagsView: TagsView) {
        
        let appearance = SCLAlertView.SCLAppearance(fieldCornerRadius: 8.0, buttonCornerRadius: 8.0)
        let alert = SCLAlertView(appearance: appearance)
        let textField = alert.addTextField("Add tag")
        textField.layer.cornerRadius = 12.0
        alert.addButton("Add") {
            guard let text = textField.text else {
                return
            }
            
            self.audioManager.addTag(title: text)
            self.configureTags()
            self.delegate?.audioItemViewController(self, didSaveItem: self.audioManager.item)
        }
        
        alert.showEdit(
            "Add Tag",
            subTitle: "Add the title for your tag here",
            closeButtonTitle: "Cancel",
            colorStyle: 0x3B08A0,
            animationStyle: .bottomToTop
        )
    }
}

// MARK: State management
extension AudioItemViewController: AudioManagerObserver {
    
    // Recording
    
    func audioManagerDidStartRecording(_ player: AudioManager) {
        btnRecord.setImage(UIImage(named: "stop-recording-button"), for: .normal)
        
        recordHidables.forEach {
            $0.disable()
        }

        tagsView?.alpha = 0.5
        tagsView?.isUserInteractionEnabled = false
    }
    
    func audioManager(_ player: AudioManager, didRecordBarWithPower decibel: Float, stepDuration: TimeInterval, totalDuration: TimeInterval) {
        lblTimer.text = TimeFormatter.formatTime(time: totalDuration)
    }
    
    func audioManagerProcessingRecording(_ player: AudioManager) {
        btnRecord.startLoading()
    }
    
    func audioManagerDidStopRecording(_ player: AudioManager) {
        if audioManager.shouldAutomaticallyShowTitleSelector {
            chooseTitle()
        }
        
        btnRecord.stopLoading()
        
        btnRecord.setImage(UIImage(named: "start-recording-button"), for: .normal)
        
        recordHidables.forEach {
            $0.enable()
        }
        
        tagsView?.alpha = 1.0
        tagsView?.isUserInteractionEnabled = true
        
        delegate?.audioItemViewController(self, didSaveItem: player.item)
    }
    
    func audioManager(_ player: AudioManager, didReachMaxRecordingLimitWithItem item: AudioItem) {
        let alert = SCLAlertView()
        alert.showWarning("Limit reached", subTitle: "You can only record a maximum of 3 minutes")
    }
    
    // Playback
    
    func audioManager(_ player: AudioManager, didStartPlaying item: AudioItem) {
        playbackHidables.forEach {
            $0.disable()
        }
    }
    
    func audioManager(_ player: AudioManager, progressedWithTime time: TimeInterval) {
        lblTimer.text = TimeFormatter.formatTime(time: time)
    }
    
    func audioManager(_ player: AudioManager, didPausePlaybackOf item: AudioItem) {
        if audioManager.isCropping == false {
            playbackHidables.forEach {
                $0.enable()
            }
        }
        
        btnCrop.enable()
    }
    
    func audioManager(_ player: AudioManager, didStopPlaying item: AudioItem) {
        if audioManager.isCropping == false {
            playbackHidables.forEach {
                $0.enable()
            }
        }
        
        btnCrop.enable()
    }
    
    // Cropping
    
    func audioManager(_ player: AudioManager, didStartCroppingItem item: AudioItem) {
        lblTimer.text = "00:00:00"
        showCropView()
    }
    
    func audioManager(_ player: AudioManager, didAdjustCropOnItem item: AudioItem) {
        lblTimer.text = "00:00:00"
    }
    
    func audioManager(_ player: AudioManager, didConfirmCropOnItem item: AudioItem) {
        let appearance = SCLAlertView.SCLAppearance(kButtonFont: UIFont.systemFont(ofSize: 16.0, weight: .light), showCloseButton: false)
        let alert = SCLAlertView(appearance: appearance)
        
        alert.addButton("Crop", backgroundColor: UIColor(named: "alert-button-colour")!, textColor: .red) {
            self.audioManager.applyCrop()
        }
        
        alert.addButton("Cancel", backgroundColor: UIColor(named: "alert-button-colour")!, textColor: .blue) {
            self.audioManager.cancelCrop()
        }
        
        alert.showWarning(
            "Crop item",
            subTitle: "Are you sure you want to crop? You will not be able to undo this action.",
            closeButtonTitle: "Not yet",
            animationStyle: .bottomToTop
        )
    }
    
    func audioManager(_ player: AudioManager, didFinishCroppingItem item: AudioItem) {
        lblTimer.text = "00:00:00"
        hideCropView()
        delegate?.audioItemViewController(self, didSaveItem: player.item)
    }
    
    func audioManagerDidCancelCropping(_ player: AudioManager) {
        lblTimer.text = "00:00:00"
        hideCropView()
        delegate?.audioItemViewController(self, didSaveItem: player.item)
    }
}

// MARK: Image attachment
extension AudioItemViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
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
                    self.delegate?.audioItemViewController(self, didSaveItem: self.audioManager.item)
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
            btnCamera.startLoading()
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
                    self.delegate?.audioItemViewController(self, didSaveItem: self.audioManager.item)
                }
            }
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        btnCamera.stopLoading()
        picker.dismiss(animated: true, completion: nil)
    }
}
