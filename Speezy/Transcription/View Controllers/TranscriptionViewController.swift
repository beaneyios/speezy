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

class TranscriptionViewController: UIViewController {
    @IBOutlet weak var collectionView: UICollectionView!
    
    var audioItem: AudioItem!
    var transcript: Transcript?
    var job: TranscriptionJob?
    var transcriber: SpeezySpeechTranscriber!
    
    var audioPlayer: AudioPlayer!
    
    private var selectedWords: [Word] = []
    
    var timer: Timer?
    var zoomFactor: CGFloat = 1
    
    @IBAction func zoomIn(_ sender: Any) {
        zoomFactor = min(zoomFactor * 1.2, 4)
        collectionView.reloadData()
    }
    
    @IBAction func zoomOut(_ sender: Any) {
        zoomFactor = max(1, zoomFactor / 1.2)
        collectionView.reloadData()
    }
    
    @IBAction func play(_ sender: Any) {
        audioPlayer.play()
    }
    
    @IBAction func quit(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func removeUhms(_ sender: Any) {
        selectedWords = transcript?.words.compactMap {
            $0.text.contains("HESITATION") ? $0 : nil
        } ?? []
        
        cut(audioItem: audioItem, from: selectedWords) { (url) in
            let audioItem = AudioItem(id: "Test", path: "test", title: "Test", date: Date(), tags: [], url: url)
            self.audioItem = audioItem
            self.audioPlayer = AudioPlayer(item: audioItem)
            self.audioPlayer.delegate = self
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
                if word.text.contains("HESITATION") {
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
        }
        
        collectionView.reloadData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        audioPlayer.stop()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        audioPlayer = AudioPlayer(item: self.audioItem)
        audioPlayer.delegate = self
        
        collectionView.register(WordCell.nib, forCellWithReuseIdentifier: "cell")
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.collectionViewLayout = LeftAlignedCollectionViewFlowLayout()
        collectionView.allowsMultipleSelection = true
        
        transcriber = SpeezySpeechTranscriber()
        
        let job = TranscriptionJob(id: "10", fileName: "transcription-test-file-trimmed")
        checkJob(job)
        return;
        
        let url = Bundle.main.url(forResource: "transcription-test-file-trimmed", withExtension: "flac")!
        createTranscriptionJob(url: url)
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
                    self.collectionView.reloadData()
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
        cell.configure(with: word, fontScale: zoomFactor)
        return cell
    }
}

extension TranscriptionViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let template = WordCell.createFromNib()
        let word = transcript!.words[indexPath.row]
        template.configure(with: word, fontScale: zoomFactor)
        template.frame.size.height = 45.0
        template.setNeedsLayout()
        template.layoutIfNeeded()
        
        let size = template.systemLayoutSizeFitting(
            CGSize(
                width: UIView.layoutFittingCompressedSize.width,
                height: 45.0
            )
        )
        
//        return CGSize(width: collectionView.frame.width, height: 45.0);
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

extension TranscriptionViewController: AudioPlayerDelegate {
    func audioPlayerDidStartPlayback(_ player: AudioPlayer) {
        
    }
    
    func audioPlayerDidPausePlayback(_ player: AudioPlayer) {
        
    }
    
    func audioPlayerDidFinishPlayback(_ player: AudioPlayer) {
        
    }
    
    func audioPlayer(_ player: AudioPlayer, progressedWithTime time: TimeInterval, seekActive: Bool) {
        let cells = collectionView.visibleCells as! [WordCell]
        
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
