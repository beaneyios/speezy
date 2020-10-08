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
    
    var timer: Timer?
    
    @IBAction func quit(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.register(WordCell.nib, forCellWithReuseIdentifier: "cell")
        collectionView.dataSource = self
        
        transcriber = SpeezySpeechTranscriber()
        
        let url = Bundle.main.url(forResource: "transcription-test-file-trimmed", withExtension: "flac")!
        
        transcriber.createTranscriptionJob(url: url) { (job) in
            self.job = job
            TranscriptionJobStorage.save(job)
            
            self.timer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true, block: { (timer) in
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
            })
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
}
