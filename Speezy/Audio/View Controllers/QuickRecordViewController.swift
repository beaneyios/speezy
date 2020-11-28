//
//  QuickRecordViewController.swift
//  Speezy
//
//  Created by Matt Beaney on 28/11/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import UIKit

protocol QuickRecordViewControllerDelegate: AnyObject {
    func quickRecordViewController(_ viewController: QuickRecordViewController, didFinishRecordingItem item: AudioItem)
    func quickRecordViewControllerDidClose(_ viewController: QuickRecordViewController)
}

class QuickRecordViewController: UIViewController {
    @IBOutlet weak var mainWaveContainer: UIView!
    @IBOutlet weak var btnRecord: SpeezyButton!
    @IBOutlet weak var lblTime: UILabel!
    @IBOutlet weak var recordingContainer: UIView!
    @IBOutlet weak var recordingContainerHeight: NSLayoutConstraint!
    @IBOutlet weak var backgroundView: UIView!
    
    weak var delegate: QuickRecordViewControllerDelegate?
    var audioManager: AudioManager!
    
    private var mainWave: PlaybackWaveView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        audioManager.addRecorderObserver(self)
        configureDialogue()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animateInDialogue()
    }
    
    @IBAction func stopRecording(_ sender: Any) {
        audioManager.stopRecording()
    }
    
    private func animateInDialogue() {
        recordingContainer.alpha = 0.0
        recordingContainerHeight.constant = 400
        
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        } completion: { _ in
            UIView.animate(withDuration: 0.3) {
                self.recordingContainer.alpha = 1.0
            } completion: { _ in
                self.configureMainSoundWave()
            }
        }
    }
    
    private func configureDialogue() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissRecording))
        backgroundView.addGestureRecognizer(tapGesture)
        backgroundView.isUserInteractionEnabled = true
        
        let panTop = UIPanGestureRecognizer(target: self, action: #selector(topPan(sender:)))
        panTop.cancelsTouchesInView = false
        recordingContainer.addGestureRecognizer(panTop)
        recordingContainer.isUserInteractionEnabled = true
        
        recordingContainerHeight.constant = 0.0
    }
    
    private func configureMainSoundWave() {
        mainWave?.removeFromSuperview()
        mainWave = nil
        
        let soundWaveView = PlaybackWaveView.instanceFromNib()
        mainWaveContainer.addSubview(soundWaveView)
        
        soundWaveView.snp.makeConstraints { (maker) in
            maker.edges.equalTo(self.mainWaveContainer)
        }
        
        soundWaveView.configure(manager: audioManager, scrollable: false) {
            self.audioManager.startRecording()
        }
        
        mainWave = soundWaveView
    }
}

extension QuickRecordViewController: AudioRecorderObserver {
    func recordingBegan() {}
    
    func recordedBar(withPower decibel: Float, stepDuration: TimeInterval, totalDuration: TimeInterval) {
        lblTime.text = TimeFormatter.formatTime(time: totalDuration)
    }
    
    func recordingProcessing() {
        btnRecord.startLoading()
    }
    
    func recordingStopped(maxLimitedReached: Bool) {
        delegate?.quickRecordViewController(self, didFinishRecordingItem: audioManager.item)
    }
}

extension QuickRecordViewController {
    @objc func dismissRecording() {
        recordingContainer.isUserInteractionEnabled = false
        self.recordingContainerHeight.constant = 0.0
        UIView.animate(withDuration: 0.3, animations: {
            self.view.layoutIfNeeded()
        }) { (finished) in
            self.discardAndClose()
        }
    }
    
    @objc func topPan(sender: UIPanGestureRecognizer) {
        let translation = sender.translation(in: view)
        
        switch sender.state {
        case .changed:
            recordingContainerHeight.constant = 400.0 - translation.y
            view.layoutIfNeeded()
            
            if translation.y > 230.0 {
                self.discardAndClose()
            }
        case .ended:
            if translation.y > 125.0 {
                dismissRecording()
            } else {
                recordingContainerHeight.constant = 400.0
                
                UIView.animate(withDuration: 0.3, animations: {
                    self.view.layoutIfNeeded()
                })
            }
        default:
            break
        }
        
        view.layoutIfNeeded()
    }
    
    private func discardAndClose() {
        audioManager.discard {
            self.delegate?.quickRecordViewControllerDidClose(self)
        }
    }
}
