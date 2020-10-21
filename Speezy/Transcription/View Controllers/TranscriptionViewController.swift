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

    var transcriber: SpeezySpeechTranscriber!
    var audioManager: AudioManager!
    
    var transcript: Transcript?
    var job: TranscriptionJob?
    private var selectedWords: [Word] = []
    
    var timer: Timer?
    var playing = false
    
    @IBOutlet weak var playbackContainer: UIView!
    @IBOutlet weak var waveContainer: UIView!
    @IBOutlet weak var cutButton: UIButton!
    @IBOutlet weak var transcribeButton: UIButton!
    
    @IBOutlet weak var collectionContainer: UIView!
    @IBOutlet weak var loadingContainer: UIView!
    @IBOutlet weak var loadingObscurer: UIImageView!
    
    @IBOutlet weak var transcribeButtonCenterY: NSLayoutConstraint!
    @IBOutlet weak var loadingContainerCenterY: NSLayoutConstraint!
    
    var waveView: PlaybackView!
    private var loadingView: SpeezyLoadingView?
    private var collectionViewController: UIViewController!
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        audioManager.stop()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        transcriber = SpeezySpeechTranscriber()
        configurePreviewWave(audioManager: audioManager)
        
        transcribeButton.layer.cornerRadius = 10.0
        transcribeButton.setTitleColor(.lightGray, for: .disabled)
        transcribeButton.setTitle("     TRANSCRIBING     ", for: .disabled)
        
        configureLoader()
        switchToLorem()
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
    
    @IBAction func createTranscriptionJob(_ sender: Any) {
        startLoading()
        
        transcribeButton.backgroundColor = .clear
        transcribeButton.isEnabled = false
        
        let job = TranscriptionJob(id: "21", fileName: "transcription-test-file-trimmed")
        checkJob(job)
        return;
        
        let url = Bundle.main.url(forResource: "transcription-test-file-trimmed", withExtension: "flac")!
        createTranscriptionJob(url: url)
    }
    
    @IBAction func playPreview(_ sender: Any) {
        audioManager.play()
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
        let loremViewController = storyboard.instantiateViewController(identifier: "lorem") as! LoremCollectionViewController
                
        addChild(loremViewController)
        collectionContainer.addSubview(loremViewController.view)
        loremViewController.view.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        loremViewController.didMove(toParent: self)
        collectionViewController = loremViewController
    }
    
    private func configureLoader() {
        loadingContainer.isHidden = true
        let loading = SpeezyLoadingView.createFromNib()
        loadingContainer.addSubview(loading)
        
        loading.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        
        loadingView = loading
    }
    
    private func startLoading() {
        loadingContainer.isHidden = false
        loadingView?.alpha = 0.0
        
        transcribeButtonCenterY.isActive = false
        loadingContainerCenterY.isActive = true
        
        UIView.animate(withDuration: 0.8) {
            self.view.layoutIfNeeded()
        } completion: { _ in
            self.loadingView?.startAnimating()
            
            UIView.animate(withDuration: 0.5) {
                self.loadingView?.alpha = 1.0
            }
        }
    }
    
    private func stopLoading(completion: @escaping () -> Void) {
        self.loadingView?.restCompletion = {
            UIView.animate(withDuration: 0.9) {
                self.loadingView?.alpha = 0.0
            } completion: { (finished) in
                self.loadingContainer.isHidden = true
                completion()
            }
        }
        
        self.loadingView?.stopAnimating()
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
    
    private func createTranscriptionJob(url: URL) {
        transcriber.createTranscriptionJob(url: url) { (job) in
            self.job = job
            TranscriptionJobStorage.save(job)
            
            self.timer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true, block: { (timer) in
                self.checkJob(job)
            })
        }
    }
    
    private func checkJob(_ job: TranscriptionJob) {
        transcriber.checkJob(id: job.id) { (result) in
            switch result {
            case let .success(transcript):
                self.timer?.invalidate()
                self.timer = nil
                self.transcript = transcript
                
                DispatchQueue.main.async {
                    UIView.animate(withDuration: 0.8) {
                        self.loadingObscurer.alpha = 0.0
                        self.transcribeButton.alpha = 0.0
                    } completion: { _ in
                        self.transcribeButton.isHidden = true
                    }
                    
                    self.hideCollection()
                    
                    self.stopLoading {
                        self.switchToTranscript()
                        
                        UIView.animate(withDuration: 0.3) {
                            self.collectionContainer.alpha = 1.0
                        }
                    }
                }
            default:
                break
            }
        }
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
            try composition.insertTimeRange( CMTimeRangeMake(start: CMTime.zero, duration: asset.duration), of: asset, at: CMTime.zero)
            
            range.reversed().forEach {
                let startTime = CMTime(seconds: $0.timestamp.start, preferredTimescale: 100)
                let endTime = CMTime(seconds: $0.timestamp.end, preferredTimescale: 100)
                composition.removeTimeRange(CMTimeRangeFromTimeToTime(start: startTime, end: endTime))
            }
            
            guard
                compatiblePresets.contains(AVAssetExportPresetAppleM4A),
                let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetAppleM4A),
                let outputURL = FileManager.default.documentsURL(with: "\(audioItem.id)\(CropKind.cut.pathExtension)")
            else {
                return
            }
            
            exportSession.outputURL = outputURL
            exportSession.outputFileType = AVFileType.m4a
            
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
