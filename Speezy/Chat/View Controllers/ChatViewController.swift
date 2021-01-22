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
    @IBOutlet weak var recordButtonContainerHeight: NSLayoutConstraint!
    @IBOutlet weak var recordBottomConstraint: NSLayoutConstraint!
    
    var activeControl: UIView?
    
    let viewModel = ChatViewModel(
        chat: Chat(
            id: "chat_1",
            chatters: [
                Chatter(id: "3ewM8SgRjJZz3me76vlEzvz1fKH3", displayName: "Matt", profileImage: nil),
                Chatter(id: "TtQ4YnmqUYXdKUAeUYydRlvyMx63", displayName: "Matt 2", profileImage: nil),
            ],
            title: "Chat 1"
        )
    )
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureRecordContainer()
        configureCollectionView()
        listenForChanges()
        addRecordButtonView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startListeningForKeyboardChanges()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        stopListeningForKeyboardChanges()
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
    
    private func animateToRecordButtonView() {
        recordButtonContainerHeight.constant = 160.0
        
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        } completion: { _ in
            self.addRecordButtonView()
        }
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
    
    private func animateToPlaybackView(item: AudioItem) {
        recordButtonContainerHeight.constant = 200.0
        
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        } completion: { _ in
            self.addPlaybackView(item: item)
        }
    }
    
    private func addPlaybackView(item: AudioItem) {
        activeControl?.removeFromSuperview()
        activeControl = nil
        
        let playbackView = ChatPlaybackView.createFromNib()
        recordButtonContainer.addSubview(playbackView)
        playbackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        playbackView.sendAction = {
            self.viewModel.sendStagedItem()
        }
        
        playbackView.textChangeAction = { text in
            self.viewModel.setMessageText(text)
        }
        
        playbackView.cancelAction = {
            self.viewModel.cancelAudioItem()
            self.viewModel.setMessageText("")
            
            playbackView.animateOut {
                self.animateToRecordButtonView()
            }            
        }
        
        playbackView.configure(audioItem: item)
        playbackView.animateIn()
        
        activeControl = playbackView
    }
    
    private func listenForChanges() {
        viewModel.didChange = { change in
            DispatchQueue.main.async {
                switch change {
                case .loaded:
                    self.collectionView.reloadData()
                case let .itemInserted(index):
                    self.collectionView.insertItems(
                        at: [
                            IndexPath(
                                item: index,
                                section: 0
                            )
                        ]
                    )
                    
                    if let playbackView = self.activeControl as? ChatPlaybackView {
                        playbackView.animateOut {
                            self.animateToRecordButtonView()
                        }
                    } else {
                        self.animateToRecordButtonView()
                    }
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
        
        viewModel.setAudioItem(item)
        animateToPlaybackView(item: item)
    }
    
    func quickRecordViewControllerDidClose(_ viewController: QuickRecordViewController) {
        viewController.view.removeFromSuperview()
        viewController.removeFromParent()
        viewController.willMove(toParent: nil)
    }
}

extension ChatViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        viewModel.items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! MessageCell
        let cellModel = viewModel.items[indexPath.row]
        cell.configure(item: cellModel)
        cell.messageDidStartPlaying = { playingCell in
            self.cellStartedPlaying(cell: playingCell, collectionView: collectionView)
        }
        
        cell.messageDidStopPlaying = { stoppingCell in
            self.cellStoppedPlaying(cell: stoppingCell, collectionView: collectionView)
        }
        
        cell.contentView.transform = CGAffineTransform(scaleX: 1, y: -1)
        viewModel.loadMoreMessages(index: indexPath.row)
        return cell
    }
    
    private func cellStartedPlaying(cell: UICollectionViewCell, collectionView: UICollectionView) {
        UIView.animate(withDuration: 0.2) {
            self.activeControl?.alpha = 0.5
            self.activeControl?.isUserInteractionEnabled = false
            cell.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
            collectionView.visibleCells.forEach {
                if $0 != cell {
                    $0.alpha = 0.5
                    $0.isUserInteractionEnabled = false
                }
            }
        }
                    
        collectionView.isScrollEnabled = false
    }
    
    private func cellStoppedPlaying(cell: UICollectionViewCell, collectionView: UICollectionView) {
        UIView.animate(withDuration: 0.2) {
            self.activeControl?.alpha = 1.0
            self.activeControl?.isUserInteractionEnabled = true
            cell.transform = CGAffineTransform.identity
            collectionView.visibleCells.forEach {
                $0.alpha = 1.0
                $0.isUserInteractionEnabled = true
            }
        }
        
        collectionView.isScrollEnabled = true
    }
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

extension ChatViewController {
    func startListeningForKeyboardChanges() {
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(
            self,
            selector: #selector(adjustForKeyboard),
            name: UIResponder.keyboardWillHideNotification, object: nil
        )
        
        notificationCenter.addObserver(
            self,
            selector: #selector(adjustForKeyboard),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
        
        let dismissGesture = UITapGestureRecognizer(
            target: self,
            action: #selector(dismissKeyboard)
        )
        
        view.addGestureRecognizer(dismissGesture)
    }
    
    func stopListeningForKeyboardChanges() {
        let notificationCenter = NotificationCenter.default
        notificationCenter.removeObserver(self)
    }
    
    @objc func adjustForKeyboard(notification: Notification) {
        guard let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }

        let keyboardScreenEndFrame = keyboardValue.cgRectValue
        let keyboardViewEndFrame = view.convert(keyboardScreenEndFrame, from: view.window)

        if notification.name == UIResponder.keyboardWillHideNotification {
            recordBottomConstraint.constant = 0.0
        } else {
            recordBottomConstraint.constant = keyboardViewEndFrame.height
        }
        
        UIView.animate(withDuration: 0.3) {
            self.view.setNeedsLayout()
        }
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}
