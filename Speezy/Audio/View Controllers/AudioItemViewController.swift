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
    
    func audioItemViewControllerDidFinish(
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
        
    @IBOutlet weak var btnTranscribeContainer: UIView!
    private var transcribeButton: TranscriptionButton?
    
    @IBOutlet weak var btnPlayback: UIButton!
    @IBOutlet weak var btnCut: UIButton!
    @IBOutlet weak var btnRecord: SpeezyButton!
    @IBOutlet weak var btnCrop: UIButton!
    @IBOutlet weak var btnTitle: UIButton!
    
    @IBOutlet weak var bgGradient: UIImageView!
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var mainWaveContainer: UIView!
        
    @IBOutlet weak var lblTimer: UILabel!
    @IBOutlet weak var btnDone: UIButton!
    
    @IBOutlet weak var draftBtnContainer: UIView!
    @IBOutlet weak var sendBtnContainer: UIView!
    
    private var draftBtn: GradientButton!
    private var sendBtn: GradientButton!
    
    weak var delegate: AudioItemViewControllerDelegate?
    
    private var mainWave: PlaybackWaveView?
    
    private var transcriptionCropUpdatesPending = false
    
    var shareAlert: SCLAlertView?
    var documentInteractionController: UIDocumentInteractionController?
    
    var audioManager: AudioManager!
    
    private var shouldShowStagedFileAlreadyExistsAlert = false
                
    override func viewDidLoad() {
        super.viewDidLoad()
        
        audioManager.downloadFile {
            DispatchQueue.main.async {
                self.prepareStagedFile()
                self.configureDependencies()
                self.configureSubviews()
            }
        }        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if transcriptionCropUpdatesPending {
            configureSubviews()
            transcriptionCropUpdatesPending = false
        }
        
        audioManager.checkTranscriptionJobs()
        showAlertForPreExistingStagedFile()
    }
    
    override func willMove(toParent parent: UIViewController?) {
        if parent == nil {
            audioManager.stopTranscriptionChecks()
            delegate?.audioItemViewControllerDidFinish(self)
        }
    }
    
     func didTapDraft() {
        delegate?.audioItemViewController(self, didSaveItemToDrafts: audioManager.item)
        delegate?.audioItemViewControllerShouldPop(self)
    }
    
    func didTapShare() {
        delegate?.audioItemViewController(self, shouldSendItem: audioManager.item)
    }
    
    @IBAction func chooseTitle(_ sender: Any) {
        showTitleAlert()
    }
    
    @IBAction func close(_ sender: Any) {
        if audioManager.hasUnsavedChanges {
            let alert = UIAlertController(
                title: "Changes not saved",
                message: "You have unsaved changes, would you like to save or discard them?",
                preferredStyle: .actionSheet
            )
            let saveAction = UIAlertAction(title: "Save", style: .default) { (action) in
                self.audioManager.save(saveAttachment: false) { (result) in
                    DispatchQueue.main.async {
                        switch result {
                        case let .success(item):
                            self.delegate?.audioItemViewController(self, didSaveItemToDrafts: item)
                            self.delegate?.audioItemViewControllerShouldPop(self)
                        case let .failure(error):
                            // TODO: Handle error
                            assertionFailure("Errored with error \(error.localizedDescription)")
                        }
                        
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
    
    @IBAction func togglePlayback(_ sender: Any) {
        audioManager.togglePlayback()
    }
    
    @IBAction func toggleCrop(_ sender: Any) {
        if audioManager.canCrop {
            delegate?.audioItemViewController(self, didPresentCropOnItem: audioManager.item)
        } else {
            let alert = SCLAlertView()
            alert.showError(
                "Clip not long enough",
                subTitle: "Your recording wasn't long enough to crop - ensure the clip is at least 5 seconds",
                closeButtonTitle: "OK"
            )
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
    func reset() {
        audioManager.seek(to: 0.0)
        configureSubviews()
    }
    
    // If the user makes an edit, then force closes the app without saving
    // we get left with a dangling staged file.
    // We should do something about this, specifically - we should show the user an alert and allow them
    // to continue editing or to discard back to the original form.
    // That's what these two functions do.
    private func prepareStagedFile() {
        audioManager.toggleDirtiness()
        if audioManager.hasUnsavedChanges {
            shouldShowStagedFileAlreadyExistsAlert = true
        }
    }
    
    private func showAlertForPreExistingStagedFile() {
        if shouldShowStagedFileAlreadyExistsAlert {
            let appearance = SCLAlertView.SCLAppearance(showCloseButton: false)
            let alert = SCLAlertView(appearance: appearance)
            alert.addButton("Discard changes") {
                self.audioManager.discard {
                    self.prepareStagedFile()
                    self.reset()
                }
            }
            
            alert.addButton("Continue with changes") {
                self.audioManager.markAsDirty()
            }
            
            alert.showEdit(
                "You have unsaved changes from your last session",
                subTitle: "You made some edits to this clip previously that weren't saved, would you like to discard these and return to the previous version?"
            )
            
            shouldShowStagedFileAlreadyExistsAlert = false
        }
    }
    
    func configureDependencies() {
        audioManager.addPlaybackObserver(self)
        audioManager.addRecorderObserver(self)
        audioManager.addTranscriptionObserver(self)
    }
    
    func configureSubviews() {
        configureDraftButton()
        configureSendButton()
        configureTranscribeButton()
        configureNavButtons()
        configureMainSoundWave()
        configureTitle()
    }
    
    private func configureSendButton() {
        let button = GradientButton.createFromNib()
        sendBtnContainer.addSubview(button)
        button.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }
        
        button.configure(title: "SEND") {
            self.didTapShare()
        }
        
        self.sendBtn = button
    }
    
    private func configureDraftButton() {
        let button = GradientButton.createFromNib()
        draftBtnContainer.addSubview(button)
        button.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }
        
        button.configure(title: "DRAFTS", backgroundImage: nil) {
            self.didTapDraft()
        }
        
        self.draftBtn = button
    }
    
    private func configureTranscribeButton() {
        transcribeButton?.removeFromSuperview()
        
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
            sendBtn.isUserInteractionEnabled = false
            sendBtn.alpha = 0.6
        }
        
        sendBtn.clipsToBounds = true
        sendBtn.layer.cornerRadius = 5.0
        draftBtn.layer.cornerRadius = 5.0
        
        draftBtn.layer.borderColor = UIColor.white.withAlphaComponent(0.8).cgColor
        draftBtn.layer.borderWidth = 1.0
    }
    
    private func configureMainSoundWave() {
        mainWave?.removeFromSuperview()
        mainWave = nil
        
        let soundWaveView = PlaybackWaveView.instanceFromNib()
        mainWaveContainer.addSubview(soundWaveView)
        
        soundWaveView.snp.makeConstraints { (maker) in
            maker.edges.equalTo(self.mainWaveContainer)
        }
        
        mainWave = soundWaveView
        mainWave?.delegate = self
        
        view.setNeedsLayout()
        view.layoutIfNeeded()
        soundWaveView.configure(manager: audioManager)
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
            let floatPercentage = percentage > 1.0 ? 1.0 : Float(percentage)
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
        
        transcribeButton?.disable()
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
        
        configureTranscribeButton()
    }
}

// MARK: PLAYBACK
extension AudioItemViewController: AudioPlayerObserver {
    func playBackBegan(on item: AudioItem) {
        playbackHidables.forEach {
            $0.disable()
        }
        
        btnPlayback.setImage(UIImage(named: "pause-button"), for: .normal)
        transcribeButton?.disable()
    }
    
    func playbackPaused(on item: AudioItem) {
        playbackHidables.forEach {
            $0.enable()
        }
        
        btnCrop.enable()
        btnCut.enable()
        configureTranscribeButton()
        
        btnPlayback.setImage(UIImage(named: "play-button"), for: .normal)
    }
    
    func playbackStopped(on item: AudioItem) {
        playbackHidables.forEach {
            $0.enable()
        }
        
        btnCrop.enable()
        configureTranscribeButton()
        btnPlayback.setImage(UIImage(named: "play-button"), for: .normal)
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
