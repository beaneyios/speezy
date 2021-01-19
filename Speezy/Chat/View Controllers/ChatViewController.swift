//
//  ChatViewController.swift
//  Speezy
//
//  Created by Matt Beaney on 11/01/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import UIKit

class ChatViewController: UIViewController, QuickRecordPresenting {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var recordButtonContainer: UIView!
    
    var activeControl: UIView?
    
    let viewModel = ChatViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureRecordContainer()
        configureCollectionView()
        listenForChanges()
        addRecordButtonView()
    }
    
    func didTapRecord() {
        presentQuickRecordDialogue(item: viewModel.newItem)
    }
    
    private func configureRecordContainer() {
        recordButtonContainer.clipsToBounds = true
        recordButtonContainer.layer.cornerRadius = 20.0
        recordButtonContainer.layer.maskedCorners = [
            .layerMinXMinYCorner, .layerMaxXMinYCorner
        ]
    }
    
    private func addRecordButtonView() {
        activeControl?.removeFromSuperview()
        activeControl = nil
        
        let recordView = ChatRecordView.createFromNib()
        recordView.recordAction = {
            self.didTapRecord()
        }

        recordButtonContainer.addSubview(recordView)
        recordView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    
        activeControl = recordView
        recordView.animateIn()
    }
    
    private func addPlaybackView() {
        activeControl?.removeFromSuperview()
        activeControl = nil
        
        let playbackView = ChatPlaybackView.createFromNib()
        recordButtonContainer.addSubview(playbackView)
        playbackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        activeControl = playbackView
        
        playbackView.animateIn()
    }
    
    private func listenForChanges() {
        viewModel.didChange = { change in
            DispatchQueue.main.async {
                switch change {
                case .loaded:
                    self.collectionView.reloadData()
                case .itemInserted(_):
                    self.collectionView.insertItems(at: [IndexPath(item: 0, section: 0)])
                }
            }
        }
        
        viewModel.listenForData()
    }
    
    private func configureCollectionView() {
        collectionView.transform = CGAffineTransform(
            scaleX: 1,
            y: -1
        )
        collectionView.register(
            MessageCell.nib,
            forCellWithReuseIdentifier: "cell"
        )
        collectionView.delegate = self
        collectionView.dataSource = self
    }
}

extension ChatViewController {
    func quickRecordViewController(_ viewController: QuickRecordViewController, didFinishRecordingItem item: AudioItem) {
        viewController.view.removeFromSuperview()
        viewController.removeFromParent()
        viewController.willMove(toParent: nil)
        
        let originalItem = item.withPath(path: "\(item.id).\(AudioConstants.fileExtension)")
        let audioManager = AudioManager(item: originalItem)
        
        addPlaybackView()
        
        // TODO: We've recorded the file, now what?
    }
    
    func quickRecordViewControllerDidClose(_ viewController: QuickRecordViewController) {
        viewController.view.removeFromSuperview()
        viewController.removeFromParent()
        viewController.willMove(toParent: nil)
    }
}

extension ChatViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        viewModel.items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! MessageCell
        let cellModel = viewModel.items[indexPath.row]
        cell.configure(item: cellModel)
        cell.contentView.transform = CGAffineTransform(scaleX: 1, y: -1)
        return cell
    }
}

extension ChatViewController: UICollectionViewDelegate {
    
}

extension ChatViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let preferredWidth = collectionView.frame.width
        let cellModel = viewModel.items[indexPath.row]
        let cell = MessageCell.createFromNib()
        
        cell.frame.size.width = preferredWidth
        cell.configure(item: cellModel)
        cell.setNeedsLayout()
        cell.layoutIfNeeded()
        
        let size = cell.systemLayoutSizeFitting(
            CGSize(
                width: preferredWidth,
                height: UIView.layoutFittingCompressedSize.height
            )
        )
        
        return CGSize(width: preferredWidth, height: size.height)
    }
}
