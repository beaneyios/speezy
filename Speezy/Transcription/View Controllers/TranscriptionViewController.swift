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
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        audioManager.stop()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        transcriptionJobManager = TranscriptionJobManager(transcriber: SpeezySpeechTranscriber())
        configurePreviewWave(audioManager: audioManager)
                
        TranscriptionJobStorage.fetchItems().forEach {
            TranscriptionJobStorage.deleteItem($0)
        }
        
        transcriptionJobManager.addTranscriptionObserver(self)        
        switchToTranscribeAction()
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 3.0) {
            self.transcript = Transcript(words: (1...30).map {
                Word(text: "\($0) word", timestamp: Timestamp(start: 0, end: 0))
            })
            self.switchToTranscript()
        }
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
        selectedWords = transcript?.words.compactMap {
            $0.text.contains("HESITATION") ? $0 : nil
        } ?? []
        
        removeSelectedWords()
    }
    
    @IBAction func playPreview(_ sender: Any) {
        audioManager.play()
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
    
    private func removeSelectedWords() {
        // TODO: Move this into the audio manager/cropper.
        cut(audioItem: audioManager.item, from: selectedWords) { (url) in
            let audioItem = AudioItem(
                id: "Test",
                path: "test",
                title: "Test",
                date: Date(),
                tags: [],
                url: url
            )
            
            // TODO: Sort this out in the audio manager
        }
        
        let orderedSelectedWords = selectedWords.sorted {
            $0.timestamp.start > $1.timestamp.start
        }
        
        // Run through each selected word in reverse order.
        // Find any words with a start time greater than that word.
        // Adjust their start times by subtracting the duration of the selected word.
        orderedSelectedWords.forEach { (selectedWord) in
            let duration = selectedWord.timestamp.end - selectedWord.timestamp.start
            
            let newWords = transcript?.words.compactMap({ (word) -> Word? in
                if self.selectedWords.contains(word) {
                    return nil
                }
                
                if word.timestamp.start > selectedWord.timestamp.start {
                    return Word(
                        text: word.text,
                        timestamp: Timestamp(
                            start: word.timestamp.start - duration,
                            end: word.timestamp.end - duration
                        )
                    )
                } else {
                    return word
                }
            }) ?? []
            
            self.transcript = Transcript(
                words: newWords
            )
            
            self.selectedWords = []
        }
        
        // TODO: Reload selected words.
    }
    
    private func hideCollection() {
        UIView.animate(withDuration: 0.3) {
            self.collectionContainer.alpha = 0.0
        } completion: { _ in
            self.collectionViewController.view.removeFromSuperview()
            self.collectionViewController.removeFromParent()
        }
    }
    
    private func cut(
        audioItem: AudioItem,
        from range: [Word],
        finished: @escaping (URL) -> Void
    ) {
        let asset = AVURLAsset(url: audioItem.url, options: [AVURLAssetPreferPreciseDurationAndTimingKey: true])
        let compatiblePresets = AVAssetExportSession.exportPresets(compatibleWith: asset)
        
        FileManager.default.deleteExistingFile(with: "\(audioItem.id)\(CropKind.cut.pathExtension)")
        
        do {
            let composition: AVMutableComposition = AVMutableComposition()
            try composition.insertTimeRange(
                CMTimeRangeMake(
                    start: CMTime.zero,
                    duration: asset.duration
                ),
                of: asset,
                at: CMTime.zero
            )
            
            range.reversed().forEach {
                let startTime = CMTime(seconds: $0.timestamp.start, preferredTimescale: 100)
                let endTime = CMTime(seconds: $0.timestamp.end, preferredTimescale: 100)
                composition.removeTimeRange(CMTimeRangeFromTimeToTime(start: startTime, end: endTime))
            }
            
            guard
                compatiblePresets.contains(AVAssetExportPresetPassthrough),
                let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetPassthrough),
                let outputURL = FileManager.default.documentsURL(with: "\(audioItem.id)\(CropKind.cut.pathExtension)")
            else {
                return
            }
            
            exportSession.outputURL = outputURL
            exportSession.outputFileType = AVFileType.wav
            
            exportSession.exportAsynchronously() {
                switch exportSession.status {
                case .failed:
                    print("Export failed: \(exportSession.error?.localizedDescription)")
                case .cancelled:
                    print("Export canceled")
                default:
                    print("Successfully cut audio")
                    DispatchQueue.main.async(execute: {
                        finished(outputURL)
                    })
                }
            }
        } catch {
            
        }
    }
}

extension TranscriptionViewController: TranscriptionObserver {
    func transcriptionJobManager(
        _ manager: TranscriptionJobManager,
        didFinishTranscribingWithAudioItemId: String,
        transcript: Transcript
    ) {
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
