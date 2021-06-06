//
//  FileInserterViewController.swift
//  Speezy
//
//  Created by Matt Beaney on 01/06/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import UIKit
import FirebaseStorage

protocol FileInserterViewControllerDelegate: AnyObject {
    func fileInserterViewController(
        _ viewController: FileInserterViewController,
        didFinishInsertionOnItem item: AudioItem
    )
    func fileInserterViewControllerDidTapClose(_ viewController: FileInserterViewController)
}

class FileInserterViewController: UIViewController {
    @IBOutlet weak var btnClose: UIButton!
    
    @IBOutlet weak var lblTime: UILabel!
    @IBOutlet weak var btnPlay: UIButton!
    @IBOutlet weak var playbackWaveContainer: UIView!
    @IBOutlet weak var btnInsert: UIButton!
    
    weak var delegate: FileInserterViewControllerDelegate?
    var manager: AudioManager!
    var fileToInsert: AudioItem!
    
    var percentage: Double = 0.0
    
    private var waveView: PlaybackWaveView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureWaveView()
        manager.addPlaybackObserver(self)
        manager.addInserterObserver(self)
    }
    
    @IBAction func togglePlayback(_ sender: Any) {
        manager.togglePlayback()
    }
    
    @IBAction func closeTapped(_ sender: Any) {
        delegate?.fileInserterViewControllerDidTapClose(self)
    }
    
    @IBAction func insertTapped(_ sender: Any) {
        CloudAudioManager.downloadAudioClip(
            atPath: "shared_audio_clips/\(fileToInsert.id).m4a",
            id: fileToInsert.id)
        { (result) in
            switch result {
            case .success:
                let position = self.manager.item.calculatedDuration * self.percentage
                self.manager.insert(self.fileToInsert, at: position)
            case let .failure(error):
                break
            }
        }
    }
        
    private func configureWaveView() {
        let playbackView = PlaybackWaveView.instanceFromNib()
        playbackWaveContainer.addSubview(playbackView)
        
        playbackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        playbackView.configure(manager: manager) {
            self.manager.startCropping()
        }
        
        playbackView.delegate = self
        waveView = playbackView
    }
}

extension FileInserterViewController: AudioInserterObserver {
    func insertingFinished(onItem item: AudioItem) {
        DispatchQueue.main.async {
            self.delegate?.fileInserterViewController(self, didFinishInsertionOnItem: item)
        }
    }
}

extension FileInserterViewController: AudioPlayerObserver {
    func playBackBegan(on item: AudioItem) {
        btnPlay.setImage(
            UIImage(named: "pause-button"), for: .normal
        )
    }

    func playbackPaused(on item: AudioItem) {
        btnPlay.setImage(
            UIImage(named: "play-button"), for: .normal
        )
    }

    func playbackStopped(on item: AudioItem) {
        btnPlay.setImage(
            UIImage(named: "play-button"), for: .normal
        )
    }

    func playbackProgressed(
        withTime time: TimeInterval,
        seekActive: Bool,
        onItem item: AudioItem,
        startOffset: TimeInterval
    ) {
        lblTime.text = TimeFormatter.formatTime(time: time + startOffset)
    }
}

extension FileInserterViewController: PlaybackWaveViewDelegate {
    func playbackView(
        _ playbackView: PlaybackWaveView,
        didFinishScrollingOnPosition percentage: CGFloat
    ) {
        self.percentage = Double(percentage)
    }
    
    func playbackView(
        _ playbackView: PlaybackWaveView,
        didScrollToPosition percentage: CGFloat,
        userInitiated: Bool
    ) {
        if userInitiated {
            let floatPercentage = percentage > 1.0 ? 1.0 : Float(percentage)
            manager.seek(to: floatPercentage)
        }
    }
}
