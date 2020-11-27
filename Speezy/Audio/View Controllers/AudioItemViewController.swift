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
    
    func audioItemViewController(
        _ viewController: AudioItemViewController,
        didPresentCutOnItem audioItem: AudioItem
    )
    
    func audioItemViewController(
        _ viewController: AudioItemViewController,
        didPresentCropOnItem audioItem: AudioItem
    )
    
    func audioItemViewControllerIsTopViewController(_ viewController: AudioItemViewController) -> Bool
}

class AudioItemViewController: UIViewController {
    
    @IBOutlet var recordHidables: [UIButton]!
    @IBOutlet var playbackHidables: [UIButton]!
        
    @IBOutlet weak var btnSend: UIButton!
    @IBOutlet weak var btnDrafts: UIButton!
        
    @IBOutlet weak var btnTranscribeContainer: UIView!
    private var transcribeButton: TranscriptionButton?
    
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
    
    @IBOutlet weak var playbackControlsContainer: UIView!
    
    @IBOutlet weak var lblTimer: UILabel!
    @IBOutlet weak var btnDone: UIButton!
    
    weak var delegate: AudioItemViewControllerDelegate?
    
    private var playbackControlsView: PlaybackControlsView?
    private var mainWave: PlaybackWaveView?
    
    private var transcriptionCropUpdatesPending = false
    
    var shareAlert: SCLAlertView?
    var documentInteractionController: UIDocumentInteractionController?
    
    var audioManager: AudioManager!
                
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureDependencies()
        configureSubviews()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if transcriptionCropUpdatesPending {
            configureSubviews()
            transcriptionCropUpdatesPending = false
        }
        
        audioManager.checkTranscriptionJobs()
    }
    
    override func willMove(toParent parent: UIViewController?) {
        if parent == nil {
            audioManager.stopTranscriptionChecks()
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
            delegate?.audioItemViewController(self, didPresentCropOnItem: audioManager.item)
        } else {
            let alert = SCLAlertView()
            alert.showError("Clip not long enough", subTitle: "Your recording wasn't long enough to crop - ensure the clip is at least 5 seconds", closeButtonTitle: "OK")
        }
    }
    
    @IBAction func toggleCut(_ sender: Any) {
        if audioManager.canCut {
            delegate?.audioItemViewController(self, didPresentCutOnItem: audioManager.item)
        } else {
            let alert = SCLAlertView()
            alert.showError(
                "Clip not long enough",
                subTitle: "Your recording wasn't long enough to cut - ensure the clip is at least 5 seconds",
                closeButtonTitle: "OK"
            )
        }
    }
    
    func presentTranscription() {
        delegate?.audioItemViewController(self, didSelectTranscribeWithManager: audioManager)
    }
}

// MARK: Configuration
extension AudioItemViewController {
    func configureDependencies() {
        audioManager.addPlaybackObserver(self)
        audioManager.addRecorderObserver(self)
        audioManager.addTranscriptionObserver(self)
    }
    
    func configureSubviews() {
        configureTranscribeButton()
        configureNavButtons()
        configureMainSoundWave()
        configurePlaybackControls()
        configureTitle()
        
        hero.isEnabled = true
        btnRecord.hero.id = "record"
        
        let presenting = HeroDefaultAnimationType.zoom
        let dismissing = HeroDefaultAnimationType.zoomOut
        hero.modalAnimationType = .selectBy(presenting: presenting, dismissing: dismissing)
    }
    
    private func configureTranscribeButton() {
        let transcribeButton = TranscriptionButton.createFromNib()
        btnTranscribeContainer.addSubview(transcribeButton)
        transcribeButton.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }
        
        if audioManager.transcriptExists {
            transcribeButton.switchToSuccessful()
        } else if audioManager.transcriptionJobExists {
            transcribeButton.switchToLoading()
        } else {
            transcribeButton.switchToNormal()
        }
        
        self.transcribeButton = transcribeButton
        
        transcribeButton.action = {
            self.presentTranscription()
        }
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
        
        let soundWaveView = PlaybackWaveView.instanceFromNib()
        mainWaveContainer.addSubview(soundWaveView)
        
        soundWaveView.snp.makeConstraints { (maker) in
            maker.edges.equalTo(self.mainWaveContainer)
        }
        
        soundWaveView.configure(manager: audioManager)
        mainWave = soundWaveView
        mainWave?.delegate = self
    }
    
    private func configureTitle() {
        btnTitle.setTitle(audioManager.item.title, for: .normal)
    }
}

extension AudioItemViewController: PlaybackWaveViewDelegate {
    func playbackView(_ playbackView: PlaybackWaveView, didFinishScrollingOnPosition percentage: CGFloat) {
        
    }
    
    func playbackView(
        _ playbackView: PlaybackWaveView,
        didScrollToPosition percentage: CGFloat,
        userInitiated: Bool
    ) {
        if userInitiated {
            let floatPercentage = Float(percentage)
            audioManager.seek(to: floatPercentage)
        }
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
}

// MARK: RECORDING
extension AudioItemViewController: AudioRecorderObserver {
    func recordingBegan() {
        btnRecord.setImage(UIImage(named: "stop-recording-button"), for: .normal)
        
        recordHidables.forEach {
            $0.disable()
        }
    }
    
    func recordedBar(withPower decibel: Float, stepDuration: TimeInterval, totalDuration: TimeInterval) {
        lblTimer.text = TimeFormatter.formatTime(time: totalDuration)
    }
    
    func recordingProcessing() {
        btnRecord.startLoading()
    }
    
    func recordingStopped(maxLimitedReached: Bool) {
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
    func playBackBegan(on item: AudioItem) {
        playbackHidables.forEach {
            $0.disable()
        }
    }
    
    func playbackPaused(on item: AudioItem) {
        playbackHidables.forEach {
            $0.enable()
        }
        
        btnCrop.enable()
        btnCut.enable()
    }
    
    func playbackStopped(on item: AudioItem) {
        playbackHidables.forEach {
            $0.enable()
        }
        
        btnCrop.enable()
    }
    
    func playbackProgressed(
        withTime time: TimeInterval,
        seekActive: Bool,
        onItem item: AudioItem,
        startOffset: TimeInterval
    ) {
        lblTimer.text = TimeFormatter.formatTime(time: time)
    }
}

extension AudioItemViewController: TranscriptionJobObserver {
    func transcriptionFinished(on itemWithId: String, transcript: Transcript) {
        transcribeButton?.switchToSuccessful()
    }
    
    func transcriptionQueued(on itemId: String) {
        transcribeButton?.switchToLoading()
    }
}
