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

    var transcriptionJobManager: TranscriptionJobManager!
    var transcriptManager: TranscriptManager!
    var audioManager: AudioManager!
    
    var transcript: Transcript?
    var job: TranscriptionJob?
    private var selectedWords: [Word] = []
    
    var playing = false
    
    @IBOutlet weak var playbackContainer: UIView!
    @IBOutlet weak var waveContainer: UIView!
    @IBOutlet weak var cutButton: UIButton!
    
    @IBOutlet weak var collectionContainer: UIView!
    
    var waveView: PlaybackView!
    private var collectionViewController: UIViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureDependencies()
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
        
    }
    
    @IBAction func playPreview(_ sender: Any) {
        audioManager.play()
    }
}

// MARK: Configuration
extension TranscriptionViewController {
    private func configureDependencies() {
        transcriptionJobManager = TranscriptionJobManager(transcriber: SpeezySpeechTranscriber())
        transcriptionJobManager.addTranscriptionObserver(self)
        transcriptManager = TranscriptManager(audioManager: audioManager)
    }
    
    private func configureContentView() {
        if transcriptionJobManager.jobExists(id: audioManager.item.id) {
            switchToLorem()
        } else if transcriptManager.transcriptExists() {
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
        transcriptViewController.transcript = transcript
        
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
    func transcriptionJobManager(
        _ manager: TranscriptionJobManager,
        didFinishTranscribingWithAudioItemId id: String,
        transcript: Transcript
    ) {
        // Save the new transcript.
        TranscriptStorage.save(transcript, id: id)
        
        DispatchQueue.main.async {
            self.transcript = transcript
            self.switchToTranscript()
        }
    }
    
    func transcriptionJobManager(
        _ manager: TranscriptionJobManager,
        didQueueTranscriptionJobWithAudioItemId: String
    ) {
        
    }
}

extension TranscriptionViewController: TranscribeActionViewControllerDelegate {
    func transcribeActionViewControllerDidSelectTranscribe(_ viewController: TranscribeActionViewController) {
        createTranscriptionJob()
    }
    
    private func createTranscriptionJob() {
        switchToLorem()
        
        transcriptionJobManager.createTranscriptionJob(
            audioId: audioManager.item.id,
            url: audioManager.item.url
        )
    }
}

extension TranscriptionViewController: AudioCropperObserver {
    func audioManager(_ manager: AudioManager, didFinishCroppingItem item: AudioItem) {
        configurePreviewWave(audioManager: audioManager)
    }
    
    func audioManager(_ manager: AudioManager, didStartCroppingItem item: AudioItem, kind: CropKind) {}
    func audioManager(_ manager: AudioManager, didAdjustCropOnItem item: AudioItem) {}
    func audioManager(_ manager: AudioManager, didMoveLeftCropHandleTo percentage: CGFloat) {}
    func audioManager(_ manager: AudioManager, didMoveRightCropHandleTo percentage: CGFloat) {}
    func audioManagerDidCancelCropping(_ manager: AudioManager) {}
}
