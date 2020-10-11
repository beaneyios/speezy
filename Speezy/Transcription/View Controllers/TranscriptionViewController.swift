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
    
    private var selectedWords: [Word] = []
    
    var timer: Timer?
    
    @IBAction func quit(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        cell.configure(with: word)
        return cell
    }
}

extension TranscriptionViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let template = WordCell.createFromNib()
        let word = transcript!.words[indexPath.row]
        template.configure(with: word)
        template.frame.size.height = 45.0
        template.setNeedsLayout()
        template.layoutIfNeeded()
        
        let size = template.systemLayoutSizeFitting(
            CGSize(
                width: UIView.layoutFittingCompressedSize.width,
                height: 45.0
            )
        )
        
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
