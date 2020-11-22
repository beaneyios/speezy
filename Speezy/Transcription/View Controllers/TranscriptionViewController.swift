//
//  TranscriptionViewController.swift
//  Speezy
//
//  Created by Matt Beaney on 13/09/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import Foundation
import UIKit
import AVKit

class TranscriptionViewController: UIViewController, PreviewWavePresenting {

    var audioManager: AudioManager!
            
    @IBOutlet weak var playbackContainer: UIView!
    @IBOutlet weak var waveContainer: UIView!
    @IBOutlet weak var playButton: UIButton!
    
    @IBOutlet weak var cutButton: UIButton!
    @IBOutlet weak var uhmButton: UIButton!
    @IBOutlet weak var zoomOutButton: UIButton!
    @IBOutlet weak var zoomInButton: UIButton!
    
    @IBOutlet weak var buttonContainer: UIView!
    @IBOutlet weak var buttonContainerHeight: NSLayoutConstraint!
    
    @IBOutlet weak var collectionContainer: UIView!
    
    var waveView: PlaybackWaveView!
    private var collectionViewController: UIViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureDependencies()
        configureButtons()
        configurePreviewWave(audioManager: audioManager)
        configureContentView()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        audioManager.stop()
    }
    
    @IBAction func zoomIn(_ sender: Any) {
        guard let transcriptViewController = collectionViewController as? TranscriptCollectionViewController else {
            return
        }
        
        transcriptViewController.zoomIn()
    }
    
    @IBAction func zoomOut(_ sender: Any) {
        guard let transcriptViewController = collectionViewController as? TranscriptCollectionViewController else {
            return
        }
        
        transcriptViewController.zoomOut()
    }
    
    @IBAction func quit(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func removeUhms(_ sender: Any) {
        audioManager.removeTranscribedUhms()
    }
    
    @IBAction func removeSelectedWords(_ sender: Any) {
        audioManager.removeSelectedTranscribedWords()
    }
    
    @IBAction func playPreview(_ sender: Any) {
        audioManager.togglePlayback()
    }
}

// MARK: Configuration
extension TranscriptionViewController {
    private func configureButtons() {
        if audioManager.transcriptExists {
            buttonContainer.isHidden = false
            buttonContainerHeight.constant = 82.0
        } else {
            buttonContainer.isHidden = true
            buttonContainerHeight.constant = 0.0
        }
        
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
        
        let transcriptExists = audioManager.transcriptExists
        cutButton.isEnabled = transcriptExists
        uhmButton.isEnabled = transcriptExists
        zoomOutButton.isEnabled = transcriptExists
        zoomInButton.isEnabled = transcriptExists
    }
    
    private func configureDependencies() {
        audioManager.addCutterObserver(self)
        audioManager.addPlaybackObserver(self)
        audioManager.addTranscriptionObserver(self)
    }
    
    private func configureContentView() {
        if audioManager.transcriptionJobExists {
            switchToLorem()
        } else if audioManager.transcriptExists {
            switchToTranscript()
        } else {
            switchToTranscribeAction()
        }
    }
    
    private func switchToTranscribeAction() {
        let storyboard = UIStoryboard(name: "Transcription", bundle: nil)
        let transcribeActionViewController = storyboard.instantiateViewController(identifier: "action") as! TranscribeActionViewController
        transcribeActionViewController.delegate = self
        
        addChild(transcribeActionViewController)
        collectionContainer.addSubview(transcribeActionViewController.view)
        transcribeActionViewController.view.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        transcribeActionViewController.didMove(toParent: self)
        collectionViewController = transcribeActionViewController
    }
    
    private func switchToTranscript() {
        let storyboard = UIStoryboard(name: "Transcription", bundle: nil)
        let transcriptViewController = storyboard.instantiateViewController(identifier: "transcript") as! TranscriptCollectionViewController
        transcriptViewController.audioManager = audioManager
        
        addChild(transcriptViewController)
        collectionContainer.addSubview(transcriptViewController.view)
        transcriptViewController.view.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        transcriptViewController.didMove(toParent: self)
        collectionViewController = transcriptViewController
    }
    
    private func switchToLorem() {
        let storyboard = UIStoryboard(name: "Transcription", bundle: nil)
        let loremViewController = storyboard.instantiateViewController(identifier: "lorem") as! TranscriptionLoadingViewController
                
        addChild(loremViewController)
        collectionContainer.addSubview(loremViewController.view)
        loremViewController.view.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        loremViewController.didMove(toParent: self)
        collectionViewController = loremViewController
    }
}

extension TranscriptionViewController: TranscriptionJobObserver {
    func transcriptionFinished(on itemWithId: String, transcript: Transcript) {
        DispatchQueue.main.async {
            self.switchToTranscript()
            self.configureButtons()
        }
    }
    
    func transcriptionQueued(on itemId: String) {}
}

extension TranscriptionViewController: TranscribeActionViewControllerDelegate {
    func transcribeActionViewControllerDidSelectTranscribe(_ viewController: TranscribeActionViewController) {
        createTranscriptionJob()
    }
    
    private func createTranscriptionJob() {
        switchToLorem()
        audioManager.startTranscriptionJob()
    }
}

extension TranscriptionViewController: AudioCutterObserver {
    func cuttingFinished(onItem item: AudioItem) {
        configurePreviewWave(audioManager: audioManager)
    }
    
    func cuttingStarted(onItem item: AudioItem) {}
    func cutRangeAdjusted(onItem item: AudioItem) {}
    func cuttingCancelled() {}
    
    func leftCropHandle(movedToPercentage percentage: CGFloat) {}
    func rightCropHandle(movedToPercentage percentage: CGFloat) {}
}

extension TranscriptionViewController: AudioPlayerObserver {
    func playBackBegan(on item: AudioItem) {
        playButton.setImage(UIImage(named: "pause-button"), for: .normal)
    }
    
    func playbackPaused(on item: AudioItem) {
        playButton.setImage(UIImage(named: "play-button"), for: .normal)
    }
    
    func playbackStopped(on item: AudioItem) {
        playButton.setImage(UIImage(named: "play-button"), for: .normal)
    }
    
    func playbackProgressed(
        withTime time: TimeInterval,
        seekActive: Bool,
        onItem item: AudioItem,
        startOffset: TimeInterval
    ) {
        
    }
}
