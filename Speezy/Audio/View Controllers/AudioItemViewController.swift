//
// AudioItemViewController.swift
//  Speezy
//
//  Created by Matt Beaney on 27/05/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import UIKit
import SwiftVideoGenerator
import SnapKit

protocol AudioItemViewControllerDelegate: AnyObject {
    func audioItemViewController(_ viewController: AudioItemViewController, didSaveItem item: AudioItem)
    func audioItemViewControllerShouldPop(_ viewController: AudioItemViewController)
}

class AudioItemViewController: UIViewController {
    @IBOutlet weak var btnCut: UIButton!
    @IBOutlet weak var btnPlayback: UIButton!
    @IBOutlet weak var btnRecord: UIButton!
    @IBOutlet weak var btnCrop: UIButton!
    @IBOutlet weak var btnShare: UIButton!
    
    @IBOutlet weak var recordContainer: UIView!
    private var recordProcessingSpinner: UIActivityIndicatorView?
    
    @IBOutlet weak var lblTimer: UILabel!
    
    @IBOutlet weak var mainWaveContainer: UIView!
    
    @IBOutlet weak var cropContainer: UIView!
    @IBOutlet weak var cropContainerHeight: NSLayoutConstraint!
    
    weak var delegate: AudioItemViewControllerDelegate?
    
    private var mainWave: LargeSoundwaveView?
    private var cropView: CropView?
    
    var documentInteractionController: UIDocumentInteractionController?
    
    var audioManager: AudioManager!
            
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureAudioManager()
        configureMainSoundWave()
        hideCropView(animated: false)
    }
    
    func configureAudioManager() {
        audioManager.addObserver(self)
    }
    
    func configureMainSoundWave() {        
        let soundWaveView = LargeSoundwaveView.instanceFromNib()
        mainWaveContainer.addSubview(soundWaveView)
        
        soundWaveView.snp.makeConstraints { (maker) in
            maker.edges.equalTo(self.mainWaveContainer)
        }
        
        soundWaveView.configure(manager: audioManager)
        mainWave = soundWaveView
    }
    
    @IBAction func close(_ sender: Any) {
        delegate?.audioItemViewControllerShouldPop(self)
    }
    
    @IBAction func toggleRecording(_ sender: Any) {
        audioManager.toggleRecording()
    }
    
    @IBAction func toggleCrop(_ sender: Any) {
        audioManager.toggleCropping()
    }
    
    @IBAction func togglePlayback(_ sender: Any) {
        audioManager.togglePlayback()
    }
    
    @IBAction func toggleCut(_ sender: Any) {
        
    }
    
    @IBAction func share(_ sender: Any) {
        share()
    }
    
    func hideCropView(animated: Bool = true) {
        guard animated else {
            cropContainerHeight.constant = 0.0
            cropContainer.alpha = 0.0
            return
        }
        
        btnCrop.setImage(UIImage(named: "crop-button"), for: .normal)
        
        btnCut.enable()
        btnRecord.enable()
        btnShare.enable()
        
        UIView.animate(withDuration: 0.3, animations: {
            self.cropContainer.alpha = 0.0
        }) { (finished) in
            self.cropContainerHeight.constant = 0.0
            UIView.animate(withDuration: 0.3, animations: {
                self.view.layoutIfNeeded()
            }) { (finished) in
                self.cropView?.removeFromSuperview()
                self.cropView = nil
                self.cropContainerHeight.constant = 0.0
            }
        }
    }
    
    func showCropView() {
        btnCrop.setImage(UIImage(named: "crop-button-selected"), for: .normal)
        
        btnCut.disable()
        btnRecord.disable()
        btnShare.disable()
                
        let cropView = CropView.instanceFromNib()
        cropView.delegate = self
        cropContainer.addSubview(cropView)
        
        cropView.snp.makeConstraints { (maker) in
            maker.edges.equalTo(self.cropContainer)
        }
        
        cropContainer.layoutIfNeeded()
        cropContainerHeight.constant = 100.0
        UIView.animate(withDuration: 0.4, animations: {
            self.view.layoutIfNeeded()
            self.cropContainer.alpha = 1.0
        }) { (finished) in
            cropView.configure(manager: self.audioManager)
        }
        
        self.cropView = cropView
    }
}

extension AudioItemViewController: CropViewDelegate {
    func cropViewDidApplyCrop(_ view: CropView) {
        let alert = UIAlertController(title: "Confirm crop", message: "Are you sure you want to crop?", preferredStyle: .alert)
        let crop = UIAlertAction(title: "Crop", style: .destructive) { (action) in
            self.audioManager.applyCrop()
        }
        
        let cancel = UIAlertAction(title: "Not yet", style: .cancel, handler: nil)
        alert.addAction(crop)
        alert.addAction(cancel)
        present(alert, animated: true, completion: nil)
    }
    
    func cropViewDidCancelCrop(_ view: CropView) {
        audioManager.cancelCrop()
    }
}

// MARK: State management
extension AudioItemViewController: AudioManagerObserver {
    func audioPlayerProcessingRecording(_ player: AudioManager) {
        btnRecord.disable()
        
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.tintColor = .white
        spinner.color = .white
        spinner.startAnimating()
        
        recordContainer.addSubview(spinner)
        spinner.snp.makeConstraints { (maker) in
            maker.center.equalToSuperview()
        }
        
        recordProcessingSpinner = spinner
    }
    
    func audioPlayerDidStopRecording(_ player: AudioManager) {
        recordProcessingSpinner?.removeFromSuperview()
        
        btnRecord.setImage(UIImage(named: "start-recording-button"), for: .normal)
        btnPlayback.enable()
        btnCut.enable()
        btnCrop.enable()
        btnRecord.enable()
        
        delegate?.audioItemViewController(self, didSaveItem: player.item)
    }
    
    func audioPlayerDidStartRecording(_ player: AudioManager) {
        btnRecord.setImage(UIImage(named: "stop-recording-button"), for: .normal)
        btnPlayback.disable()
        btnCut.disable()
        btnCrop.disable()
    }
    
    func audioPlayer(_ player: AudioManager, didRecordBarWithPower decibel: Float, duration: TimeInterval) {
        // No op
    }
    
    func audioPlayer(_ player: AudioManager, progressedWithTime time: TimeInterval) {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .positional
        formatter.allowedUnits = [ .hour, .minute, .second ]
        formatter.zeroFormattingBehavior = [ .pad ]
        let durationString = formatter.string(from: time) ?? "\(time)"
        lblTimer.text = durationString
    }
    
    func audioPlayer(_ player: AudioManager, didStartPlaying item: AudioItem) {
        btnPlayback.setImage(UIImage(named: "pause-button"), for: .normal)
        btnRecord.disable()
        btnCut.disable()
        btnCrop.disable()
    }
    
    func audioPlayer(_ player: AudioManager, didPausePlaybackOf item: AudioItem) {
        btnPlayback.setImage(UIImage(named: "play-button"), for: .normal)
        btnRecord.enable()
        btnCut.enable()
        btnCrop.enable()
    }
    
    func audioPlayerDidStop(_ player: AudioManager) {
        btnPlayback.setImage(UIImage(named: "play-button"), for: .normal)
        btnRecord.enable()
        btnCut.enable()
        btnCrop.enable()
    }
    
    func audioPlayer(_ player: AudioManager, didStartCroppingItem item: AudioItem) {
        lblTimer.text = "00:00:00"
        showCropView()
    }
    
    func audioPlayer(_ player: AudioManager, didAdjustCropOnItem item: AudioItem) {
        lblTimer.text = "00:00:00"
    }
    
    func audioPlayer(_ player: AudioManager, didFinishCroppingItem item: AudioItem) {
        lblTimer.text = "00:00:00"
        hideCropView()
        delegate?.audioItemViewController(self, didSaveItem: player.item)
    }
    
    func audioPlayerDidCancelCropping(_ player: AudioManager) {
        lblTimer.text = "00:00:00"
        hideCropView()
        delegate?.audioItemViewController(self, didSaveItem: player.item)
    }
}

// MARK: For later.
extension AudioItemViewController {
    func share() {
        btnShare.disable()
        guard let image = UIImage(named: "speezy") else {
            return
        }
        
        let audioURL = audioManager.item.url
        
        VideoGenerator.fileName = "Speezy Audio File"
        VideoGenerator.shouldOptimiseImageForVideo = true
        VideoGenerator.current.generate(withImages: [image], andAudios: [audioURL], andType: .single, { (progress) in
            print(progress)
        }, outcome: { (outcome) in
            switch outcome {
            case let .success(url):
                DispatchQueue.main.async {
                    self.sendToWhatsApp(url: url)
                }
            case let .failure(error):
                print("FAILED \(error.localizedDescription)")
                return
            }
        })
    }
    
    func sendToWhatsApp(url: URL) {
        documentInteractionController = UIDocumentInteractionController(url: url)
        documentInteractionController?.uti = "net.whatsapp.video"
        documentInteractionController?.annotation = "Test"
        documentInteractionController?.presentOpenInMenu(
            from: CGRect(x: 0, y: 0, width: 0, height: 0),
            in: view,
            animated: true
        )
    }
}

extension UIButton {
    func disable() {
        isEnabled = false
        alpha = 0.5
    }
    
    func enable() {
        isEnabled = true
        alpha = 1.0
    }
}
