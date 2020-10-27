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
    func audioItemViewController(
        _ viewController: AudioItemViewController,
        shouldSendItem item: AudioItem
    )
    
    func audioItemViewController(
        _ viewController: AudioItemViewController,
        didSaveItemToDrafts item: AudioItem
    )
    
    func audioItemViewControllerShouldPop(
        _ viewController: AudioItemViewController
    )
    
    func audioItemViewController(
        _ viewController: AudioItemViewController,
        didSelectTranscribeWithManager manager: AudioManager
    )
    
    func audioItemViewControllerIsTopViewController(_ viewController: AudioItemViewController) -> Bool
}

class AudioItemViewController: UIViewController {
    
    @IBOutlet var recordHidables: [UIButton]!
    @IBOutlet var playbackHidables: [UIButton]!
    @IBOutlet var cropHidables: [UIButton]!
    @IBOutlet var cutHidables: [UIButton]!
        
    @IBOutlet weak var btnSend: UIButton!
    @IBOutlet weak var btnDrafts: UIButton!
    
    @IBOutlet weak var btnCut: UIButton!
    @IBOutlet weak var btnRecord: SpeezyButton!
    @IBOutlet weak var btnCrop: UIButton!
    @IBOutlet weak var btnShare: UIButton!
    @IBOutlet weak var btnTitle: UIButton!
    
    @IBOutlet weak var bgGradient: UIImageView!
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var controlButtonsHeight: NSLayoutConstraint!
    
    @IBOutlet weak var recordContainer: UIView!
    @IBOutlet weak var mainWaveContainer: UIView!
    
    @IBOutlet weak var cropContainer: UIView!
    @IBOutlet weak var cropWaveContainer: UIView!
    @IBOutlet weak var cropContainerHeight: NSLayoutConstraint!
    
    @IBOutlet weak var playbackControlsContainer: UIView!
    
    @IBOutlet weak var lblTimer: UILabel!
    @IBOutlet weak var btnDone: UIButton!
    
    weak var delegate: AudioItemViewControllerDelegate?
    
    private var playbackControlsView: PlaybackControlsView?
    private var mainWave: PlaybackView?
    private var cropView: CropView?
    
    private var transcriptionCropUpdatesPending = false
    
    var shareAlert: SCLAlertView?
    var documentInteractionController: UIDocumentInteractionController?
    
    var audioManager: AudioManager!
                
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureAudioManager()
        configureSubviews()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if transcriptionCropUpdatesPending {
            configureSubviews()
            transcriptionCropUpdatesPending = false
        }
    }
    
    @IBAction func saveToDrafts(_ sender: Any) {
        let saveAction = {
            self.audioManager.save(saveAttachment: false) { (item) in
                self.delegate?.audioItemViewController(self, didSaveItemToDrafts: item)
                self.delegate?.audioItemViewControllerShouldPop(self)
            }
        }
        
        if audioManager.noTitleSet {
            self.showTitleAlert {
                saveAction()
            }
        } else {
            saveAction()
        }
    }
    
    @IBAction func send(_ sender: Any) {
        audioManager.save(saveAttachment: false) { (item) in
            DispatchQueue.main.async {
                NSLog("Going to call delegate \(self.delegate)")
                self.delegate?.audioItemViewController(self, shouldSendItem: item)
            }
        }
    }
    
    @IBAction func chooseTitle(_ sender: Any) {
        showTitleAlert()
    }
    
    @IBAction func close(_ sender: Any) {
        if audioManager.hasUnsavedChanges {
            let alert = UIAlertController(title: "Changes not saved", message: "You have unsaved changes, would you like to save or discard them?", preferredStyle: .actionSheet)
            let saveAction = UIAlertAction(title: "Save", style: .default) { (action) in
                self.audioManager.save(saveAttachment: false) { (item) in
                    DispatchQueue.main.async {
                        self.delegate?.audioItemViewController(self, didSaveItemToDrafts: item)
                        self.delegate?.audioItemViewControllerShouldPop(self)
                    }
                }
            }
            
            let discardAction = UIAlertAction(title: "Discard", style: .destructive) { (action) in
                self.audioManager.discard {
                    self.delegate?.audioItemViewControllerShouldPop(self)
                }
            }
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            
            alert.addAction(saveAction)
            alert.addAction(discardAction)
            alert.addAction(cancelAction)
            present(alert, animated: true, completion: nil)
        } else {
            delegate?.audioItemViewControllerShouldPop(self)
        }
    }
    
    @IBAction func toggleRecording(_ sender: Any) {
        audioManager.toggleRecording()
    }
    
    @IBAction func toggleCrop(_ sender: Any) {
        if audioManager.canCrop {
            audioManager.toggleCrop()
        } else {
            let alert = SCLAlertView()
            alert.showError("Clip not long enough", subTitle: "Your recording wasn't long enough to crop - ensure the clip is at least 5 seconds", closeButtonTitle: "OK")
        }
    }
    
    @IBAction func applyCrop(_ sender: Any) {
        audioManager.stop()
        
        if audioManager.hasActiveCrop == false {
            audioManager.cancelCrop()
            return
        }
        
        let alert = UIAlertController(title: "Confirm crop", message: "Are you sure you want to crop?", preferredStyle: .alert)
        let cropAction = UIAlertAction(title: "Crop", style: .destructive) { (action) in
            self.audioManager.applyCrop()
        }
        
        let cancelAction = UIAlertAction(title: "Not yet", style: .cancel, handler: nil)
        alert.addAction(cropAction)
        alert.addAction(cancelAction)
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction func cancelCrop(_ sender: Any) {
        audioManager.cancelCrop()
    }
    
    @IBAction func toggleCut(_ sender: Any) {
        if audioManager.canCrop {
            audioManager.toggleCut()
        } else {
            let alert = SCLAlertView()
            alert.showError(
                "Clip not long enough",
                subTitle: "Your recording wasn't long enough to cut - ensure the clip is at least 5 seconds",
                closeButtonTitle: "OK"
            )
        }
    }
    
    @IBAction func presentTranscription(_ sender: Any) {
        delegate?.audioItemViewController(self, didSelectTranscribeWithManager: audioManager)
    }
}

// MARK: Configuration
extension AudioItemViewController {
    func configureAudioManager() {
        audioManager.addPlayerObserver(self)
        audioManager.addRecorderObserver(self)
        audioManager.addCropperObserver(self)
    }
    
    func configureSubviews() {
        configureNavButtons()
        configureMainSoundWave()
        configurePlaybackControls()
        configureTitle()
        hideCropView(animated: false)
        
        hero.isEnabled = true
        btnRecord.hero.id = "record"
        
        let presenting = HeroDefaultAnimationType.zoom
        let dismissing = HeroDefaultAnimationType.zoomOut
        hero.modalAnimationType = .selectBy(presenting: presenting, dismissing: dismissing)
    }
    
    private func configureNavButtons() {
        if audioManager.duration <= 0.0 {
            btnSend.isEnabled = false
            btnSend.alpha = 0.6
        }
        
        btnSend.layer.cornerRadius = 5.0
        btnDrafts.layer.cornerRadius = 5.0
        
        btnDrafts.layer.borderColor = UIColor.white.withAlphaComponent(0.8).cgColor
        btnDrafts.layer.borderWidth = 1.0
    }
    
    private func configurePlaybackControls() {
        playbackControlsContainer.subviews.forEach {
            $0.removeFromSuperview()
        }
        
        let playbackControlsView = PlaybackControlsView.instanceFromNib()
        playbackControlsView.configure(with: audioManager)
        playbackControlsContainer.addSubview(playbackControlsView)
        playbackControlsView.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }
    }
    
    private func configureMainSoundWave() {
        mainWave?.removeFromSuperview()
        mainWave = nil
        
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
}

// MARK: Actions
extension AudioItemViewController {
    private func showTitleAlert(completion: (() -> Void)? = nil) {
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
            completion?()
        }
        
        alert.showEdit(
            "Title",
            subTitle: "Add the title for your audio file here",
            closeButtonTitle: "Cancel",
            colorStyle: 0x3B08A0,
            animationStyle: .topToBottom
        )
    }
    
    private func showCutView() {
        cutHidables.forEach {
            $0.disable()
        }
        
        cropContainerHeight.constant = 100.0
        controlButtonsHeight.constant = 0.0
        
        UIView.animate(withDuration: 0.4, animations: {
            self.view.layoutIfNeeded()
            self.cropContainer.alpha = 1.0
        }) { (finished) in
            let cropView = CropView.instanceFromNib()
            cropView.alpha = 0.0
            self.cropWaveContainer.addSubview(cropView)
            
            cropView.snp.makeConstraints { (maker) in
                maker.edges.equalTo(self.cropWaveContainer)
            }
            
            self.cropView = cropView
            cropView.configure(manager: self.audioManager, cropKind: .cut)
            
            UIView.animate(withDuration: 0.3) {
                cropView.alpha = 1.0
            }
            
            self.scrollView.setContentOffset(
                CGPoint(x: 0, y: 100.0),
                animated: true
            )
        }
    }
    
    private func hideCropView() {
        cutHidables.forEach {
            $0.enable()
        }
        
        controlButtonsHeight.constant = 80.0
        
        UIView.animate(withDuration: 0.3, animations: {
            self.view.layoutIfNeeded()
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
    
    private func showCropView() {
        cropHidables.forEach {
            $0.disable()
        }
        
        cropContainerHeight.constant = 100.0
        controlButtonsHeight.constant = 0.0
        
        UIView.animate(withDuration: 0.4, animations: {
            self.view.layoutIfNeeded()
            self.cropContainer.alpha = 1.0
        }) { (finished) in
            let cropView = CropView.instanceFromNib()
            cropView.alpha = 0.0
            self.cropWaveContainer.addSubview(cropView)
            
            cropView.snp.makeConstraints { (maker) in
                maker.edges.equalTo(self.cropWaveContainer)
            }
            
            self.cropView = cropView
            cropView.configure(manager: self.audioManager, cropKind: .trim)
            
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
            controlButtonsHeight.constant = 80.0
            cropContainerHeight.constant = 0.0
            cropContainer.alpha = 0.0
            return
        }
        
        btnCrop.setImage(UIImage(named: "crop-button"), for: .normal)
        
        cropHidables.forEach {
            $0.enable()
        }
        
        controlButtonsHeight.constant = 80.0
        
        UIView.animate(withDuration: 0.3, animations: {
            self.view.layoutIfNeeded()
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

// MARK: RECORDING
extension AudioItemViewController: AudioRecorderObserver {
    func audioManagerDidStartRecording(_ player: AudioManager) {
        btnRecord.setImage(UIImage(named: "stop-recording-button"), for: .normal)
        
        recordHidables.forEach {
            $0.disable()
        }
    }
    
    func audioManager(_ manager: AudioManager, didRecordBarWithPower decibel: Float, stepDuration: TimeInterval, totalDuration: TimeInterval) {
        lblTimer.text = TimeFormatter.formatTime(time: totalDuration)
    }
    
    func audioManagerProcessingRecording(_ player: AudioManager) {
        btnRecord.startLoading()
    }
    
    func audioManagerDidStopRecording(_ player: AudioManager, maxLimitedReached: Bool) {
        if maxLimitedReached {
            let alert = SCLAlertView()
            alert.showWarning("Limit reached", subTitle: "You can only record a maximum of 2 minutes")
        }
        
        btnRecord.stopLoading()
        
        btnRecord.setImage(UIImage(named: "start-recording-button"), for: .normal)
        
        recordHidables.forEach {
            $0.enable()
        }
    }
}

// MARK: PLAYBACK
extension AudioItemViewController: AudioPlayerObserver {
    func audioManager(_ manager: AudioManager, didStartPlaying item: AudioItem) {
        playbackHidables.forEach {
            $0.disable()
        }
    }
    
    func audioManager(_ manager: AudioManager, progressedWithTime time: TimeInterval, seekActive: Bool) {
        lblTimer.text = TimeFormatter.formatTime(time: time)
    }
    
    func audioManager(_ manager: AudioManager, didPausePlaybackOf item: AudioItem) {
        if audioManager.isCropping == false {
            playbackHidables.forEach {
                $0.enable()
            }
        }
        
        btnCrop.enable()
        btnCut.enable()
    }
    
    func audioManager(_ manager: AudioManager, didStopPlaying item: AudioItem) {
        if audioManager.isCropping == false {
            playbackHidables.forEach {
                $0.enable()
            }
        }
        
        btnCrop.enable()
    }
}

// MARK: CROPPING
extension AudioItemViewController: AudioCropperObserver {
    func audioManager(_ manager: AudioManager, didStartCroppingItem item: AudioItem, kind: CropKind) {
        lblTimer.text = "00:00:00"

        switch kind {
        case .cut:
            showCutView()
        case .trim:
            showCropView()
        }

        scrollView.isScrollEnabled = false
    }
    
    func audioManager(_ manager: AudioManager, didMoveLeftCropHandleTo percentage: CGFloat) {
        // no op
    }
    
    func audioManager(_ manager: AudioManager, didMoveRightCropHandleTo percentage: CGFloat) {
        // no op
    }
    
    func audioManager(_ manager: AudioManager, didAdjustCropOnItem item: AudioItem) {
        lblTimer.text = "00:00:00"
    }

    func audioManager(_ manager: AudioManager, didFinishCroppingItem item: AudioItem) {
        if delegate?.audioItemViewControllerIsTopViewController(self) ?? false {
            lblTimer.text = "00:00:00"
            hideCropView()
            scrollView.isScrollEnabled = true
        } else {
            transcriptionCropUpdatesPending = true
        }
    }
    
    func audioManagerDidCancelCropping(_ player: AudioManager) {
        lblTimer.text = "00:00:00"
        hideCropView()
        scrollView.isScrollEnabled = true
    }
}
