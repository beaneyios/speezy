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
    
    var transcript: Transcript?
    var job: TranscriptionJob?
    var transcriber: SpeezySpeechTranscriber!
    
    var audioManager: AudioManager!
    
    private var selectedWords: [Word] = []
    
    var timer: Timer?
    var zoomFactor: CGFloat = 1
    var playing = false
    
    @IBOutlet weak var playbackContainer: UIView!
    @IBOutlet weak var waveContainer: UIView!
    @IBOutlet weak var cutButton: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var transcribeButton: UIButton!
    
    @IBOutlet weak var loadingContainer: UIView!
    
    var waveView: PlaybackView!
    var loadingView: SpeezyLoadingView?
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        audioManager.stop()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        audioManager.addPlayerObserver(self)
        
        collectionView.register(WordCell.nib, forCellWithReuseIdentifier: "cell")
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.collectionViewLayout = LeftAlignedCollectionViewFlowLayout()
        collectionView.allowsMultipleSelection = true
        
        transcriber = SpeezySpeechTranscriber()
        
        configurePreviewWave(audioManager: audioManager)
        
        transcribeButton.layer.cornerRadius = 10.0
        
        transcribeButton.setTitle("     TRANSCRIBING YOUR CLIP     ", for: .disabled)
        configureLoader()
    }
    
    @IBAction func zoomIn(_ sender: Any) {
        zoomFactor = min(zoomFactor * 1.2, 4)
        collectionView.reloadData()
    }
    
    @IBAction func zoomOut(_ sender: Any) {
        zoomFactor = max(1, zoomFactor / 1.2)
        collectionView.reloadData()
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
        
        transcribeButton.backgroundColor = .lightGray
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
    
    private func configureLoader() {
        loadingContainer.isHidden = true
        let loading = SpeezyLoadingView.createFromNib()
        loadingContainer.addSubview(loading)
        
        loading.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        
        self.loadingView = loading
    }
    
    private func startLoading() {
        loadingContainer.isHidden = false
        
        loadingView?.startAnimating()
        loadingView?.alpha = 0.0
        
        UIView.animate(withDuration: 0.5) {
            self.loadingView?.alpha = 1.0
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
        
        collectionView.reloadData()
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
        self.transcriber.checkJob(id: job.id) { (result) in
            switch result {
            case let .success(transcript):
                self.timer?.invalidate()
                self.timer = nil
                self.transcript = transcript
                
                DispatchQueue.main.async {
                    UIView.animate(withDuration: 0.8) {
                        self.transcribeButton.alpha = 0.0
                    } completion: { _ in
                        self.transcribeButton.isHidden = true
                    }
                    
                    self.collectionView.alpha = 0.0
                    self.collectionView.reloadData()
                    
                    self.stopLoading {
                        UIView.animate(withDuration: 0.3) {
                            self.collectionView.alpha = 1.0
                        }
                    }
                }
            default:
                break
            }
        }
    }
    
    func cut(
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

extension TranscriptionViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        transcript?.words.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! WordCell
        let word = transcript!.words[indexPath.row]
        let isSelected = selectedWords.contains(word)
        cell.configure(with: word, isSelected: isSelected, fontScale: zoomFactor)
        return cell
    }
}

extension TranscriptionViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let template = WordCell.createFromNib()
        let word = transcript!.words[indexPath.row]
        let isSelected = selectedWords.contains(word)
        template.configure(with: word, isSelected: isSelected, fontScale: zoomFactor)
        template.frame.size.height = 45.0
        template.setNeedsLayout()
        template.layoutIfNeeded()
        
        let size = template.systemLayoutSizeFitting(
            CGSize(
                width: UIView.layoutFittingCompressedSize.width,
                height: 45.0
            )
        )
        
        if size.width > collectionView.frame.width {
            return CGSize(width: collectionView.frame.width, height: size.height * 2.0)
        }
        
        return size
    }
    
    private func toggleWord(at indexPath: IndexPath) {
        guard let selectedWord = transcript?.words[indexPath.row] else {
            assertionFailure("No transcript found.")
            return
        }
        
        if let indexOfWord = selectedWords.firstIndex(of: selectedWord) {
            selectedWords.remove(at: indexOfWord)
        } else {
            selectedWords.append(selectedWord)
        }
        
        print(selectedWords.map { $0.text })
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        toggleWord(at: indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        toggleWord(at: indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 4.0
    }
}

extension TranscriptionViewController: AudioPlayerObserver {
    func audioManager(_ manager: AudioManager, didStartPlaying item: AudioItem) {
        
    }
    
    func audioManager(_ manager: AudioManager, didPausePlaybackOf item: AudioItem) {
        
    }
    
    func audioManager(_ manager: AudioManager, didStopPlaying item: AudioItem) {
        
    }
    
    func audioManager(_ manager: AudioManager, progressedWithTime time: TimeInterval, seekActive: Bool) {
        let cells = collectionView.visibleCells as! [WordCell]
        
        let activeWord = transcript!.words.first {
            $0.timestamp.start < time && $0.timestamp.end > time
        }
        
        if let activeWord = activeWord, let indexOfWord = transcript!.words.firstIndex(of: activeWord){
            collectionView.scrollToItem(at: IndexPath(item: indexOfWord, section: 0), at: .centeredVertically, animated: false)
        }
        
        cells.forEach {
            let indexPath = collectionView.indexPath(for: $0)!
            let word = transcript!.words[indexPath.item]
            if word.timestamp.start < time && word.timestamp.end > time {
                $0.highlightActive()
            } else {
                $0.highlightInactive()
            }
        }
    }
}
