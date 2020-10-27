//
//  TranscriptCollectionViewController.swift
//  Speezy
//
//  Created by Matt Beaney on 21/10/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import UIKit
import GhostTypewriter

protocol TranscriptCollectionViewControllerDelegate: AnyObject {
    func transcriptCollectionViewController(_ viewController: TranscriptCollectionViewController, didSelectWord: [Word])
}

class TranscriptCollectionViewController: UIViewController {
    
    var audioManager: AudioManager!
    var transcriptManager: TranscriptManager!
    
    var zoomFactor: CGFloat = 1
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var confirmationContainer: UIView!
    @IBOutlet weak var tickIcon: UIImageView!
    @IBOutlet weak var confirmationLabel: TypewriterLabel!
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        UIView.animate(withDuration: 0.3) {
            self.confirmationContainer.alpha = 1.0
            self.tickIcon.transform = CGAffineTransform(
                scaleX: 1.3,
                y: 1.3
            )
        } completion: { (finished) in
            UIView.animate(withDuration: 0.3) {
                self.tickIcon.transform = CGAffineTransform.identity
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.5) {
            UIView.animate(withDuration: 0.5) {
                self.collectionView.alpha = 1.0
                self.confirmationContainer.alpha = 0.0
            }
        }
        
        confirmationLabel.text = "Finished transcribing your file!"
        confirmationLabel.typingTimeInterval = 0.02
        confirmationLabel.startTypewritingAnimation()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureCollectionView()
        configureConfirmationContainer()
        configureDependencies()
    }
    
    func zoomIn() {
        zoomFactor = min(zoomFactor * 1.2, 4)
        collectionView.reloadData()
    }
    
    func zoomOut() {
        zoomFactor = max(1, zoomFactor / 1.2)
        collectionView.reloadData()
    }
    
    private func configureDependencies() {
        transcriptManager.addTranscriptObserver(self)
        audioManager.addPlayerObserver(self)
    }
    
    private func configureConfirmationContainer() {
        confirmationContainer.alpha = 0.0
    }
    
    private func configureCollectionView() {
        collectionView.register(WordCell.nib, forCellWithReuseIdentifier: "cell")
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.allowsMultipleSelection = true
        collectionView.collectionViewLayout = LeftAlignedCollectionViewFlowLayout()
        collectionView.alpha = 0.0
    }
}

extension TranscriptCollectionViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        transcriptManager.numberOfWords
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! WordCell
        
        if let word = transcriptManager.word(for: indexPath.row) {
            let isSelected = transcriptManager.isSelected(word: word)
            cell.configure(with: word, isSelected: isSelected, fontScale: zoomFactor)
        }
        
        return cell
    }
}

extension TranscriptCollectionViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let template = WordCell.createFromNib()
        
        if let word = transcriptManager.word(for: indexPath.row) {
            let isSelected = transcriptManager.isSelected(word: word)
            template.configure(with: word, isSelected: isSelected, fontScale: zoomFactor)
        }
        
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
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        transcriptManager.toggleSelection(at: indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        transcriptManager.toggleSelection(at: indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 4.0
    }
}

extension TranscriptCollectionViewController: AudioPlayerObserver {
    func audioManager(_ manager: AudioManager, progressedWithTime time: TimeInterval, seekActive: Bool) {
        let cells = collectionView.visibleCells as! [WordCell]
                
        if let currentWordIndex = transcriptManager.currentPlayingWordIndex(at: time) {
            collectionView.scrollToItem(at: IndexPath(item: currentWordIndex, section: 0), at: .centeredVertically, animated: false)
        }
        
        cells.forEach {
            guard
                let indexPath = collectionView.indexPath(for: $0),
                let word = transcriptManager.word(for: indexPath.row)
            else {
                return
            }
            
            if word.timestamp.start < time && word.timestamp.end > time {
                $0.highlightActive()
            } else {
                $0.highlightInactive()
            }
        }
    }
    
    func audioManager(_ manager: AudioManager, didStartPlaying item: AudioItem) {}
    func audioManager(_ manager: AudioManager, didPausePlaybackOf item: AudioItem) {}
    func audioManager(_ manager: AudioManager, didStopPlaying item: AudioItem) {}
}

extension TranscriptCollectionViewController: TranscriptObserver {
    func transcriptManager(_ manager: TranscriptManager, didFinishEditingTranscript transcript: Transcript) {
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
    }
}
