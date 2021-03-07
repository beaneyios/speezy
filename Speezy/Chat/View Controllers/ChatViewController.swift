//
//  ChatViewController.swift
//  Speezy
//
//  Created by Matt Beaney on 11/01/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import UIKit

protocol ChatViewControllerDelegate: AnyObject {
    func chatViewControllerDidTapBack(_ viewController: ChatViewController)
    func chatViewController(_ viewController: ChatViewController, didSelectEditWithAudioManager manager: AudioManager)
}

class ChatViewController: UIViewController, QuickRecordPresenting, ChatViewModelDelegate {
    
    @IBOutlet weak var emptyView: UIView!
    @IBOutlet weak var groupTitleLabel: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var recordButtonContainer: UIView!
    @IBOutlet weak var recordButtonContainerHeight: NSLayoutConstraint!
    @IBOutlet weak var recordBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var notificationLabel: UILabel!
    
    var viewHeight: CGFloat {
        collectionView.frame.height
    }
    
    weak var delegate: ChatViewControllerDelegate?
    private var activeAudioManager: AudioManager?
    
    var activeControl: UIView?
    var viewModel: ChatViewModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureRecordContainer()
        configureCollectionView()
        addRecordButtonView()
        listenForChanges()
        groupTitleLabel.text = viewModel.groupTitleText
        collectionView.alpha = 0.0
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startListeningForKeyboardChanges()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        stopListeningForKeyboardChanges()
        cancelAudioPlayback()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        notificationLabel.layer.cornerRadius = notificationLabel.frame.width / 2.0
        notificationLabel.clipsToBounds = true
        notificationLabel.isHidden = true
    }
    
    override func willMove(toParent parent: UIViewController?) {
        super.willMove(toParent: parent)
        if parent == nil {
            viewModel.stopObserving()
        }
    }
    
    func showNotificationLabel() {
        notificationLabel.isHidden = false
        UIView.animate(withDuration: 0.3) {
            self.notificationLabel.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        } completion: { _ in
            UIView.animate(withDuration: 0.3) {
                self.notificationLabel.transform = CGAffineTransform.identity
            }
        }
    }
    
    func didTapRecord() {
        presentQuickRecordDialogue(item: viewModel.newItem)
    }
    
    @IBAction func didTapOptions(_ sender: Any) {
        let alert = UIAlertController(
            title: "Chat options",
            message: nil,
            preferredStyle: .actionSheet
        )
        
        let leaveChat = UIAlertAction(
            title: "Leave chat",
            style: .destructive
        ) { _ in
            self.viewModel.leaveChat()
        }
        
        let cancel = UIAlertAction(
            title: "Cancel",
            style: .cancel,
            handler: nil
        )
        
        alert.addAction(leaveChat)
        alert.addAction(cancel)
        
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction func didTapBack(_ sender: Any) {
        delegate?.chatViewControllerDidTapBack(self)
    }
    
    func sendEditedAudioItem(_ item: AudioItem) {
        guard let playbackView = activeControl as? ChatPlaybackView else {
            return
        }
        
        playbackView.showLoader()
        viewModel.setAudioItem(item)
        viewModel.sendStagedItem()
    }
    
    func discardAudioItem(_ item: AudioItem) {
        viewModel.discardItem(item)
    }
    
    func applyChangesToAudioItem(_ item: AudioItem) {
        guard let playbackView = activeControl as? ChatPlaybackView else {
            return
        }
        
        viewModel.setAudioItem(item)
        playbackView.configure(audioItem: item)
    }
    
    private func cancelAudioPlayback() {
        activeAudioManager?.stop()
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
        
        playbackView.editAudioAction = { audioManager in
            // We don't want this going into the studio view "dirty".
            // The editor picks this up and assumes the user previously quit the
            // studio view without saving, which isn't the case here.
            audioManager.markAsClean()
            self.delegate?.chatViewController(self, didSelectEditWithAudioManager: audioManager)
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
            self.applyChange(change: change)
        }
        
        viewModel.delegate = self
        viewModel.listenForData()
    }
    
    private func applyChange(change: ChatViewModel.Change) {
        DispatchQueue.main.async {
            switch change {
            case .loaded:
                self.toggleEmptyView()
                self.collectionView.reloadData()
                
                UIView.animate(withDuration: 0.3) {
                    self.collectionView.alpha = 1.0
                }
            case let .itemRemoved(index: index):
                self.toggleEmptyView()
                self.collectionView.deleteItems(
                    at: [
                        IndexPath(
                            item: index,
                            section: 0
                        )
                    ]
                )
            case let .itemInserted(index):
                self.toggleEmptyView()
                self.collectionView.insertItems(
                    at: [
                        IndexPath(
                            item: index,
                            section: 0
                        )
                    ]
                )
            case let .readStatusReloaded(indexes):
                let indexPaths = indexes.map {
                    IndexPath(item: $0, section: 0)
                }
                
                self.collectionView.visibleCells.forEach {
                    if
                        let indexPath = self.collectionView.indexPath(for: $0),
                        indexPaths.contains(indexPath),
                        let messageCell = $0 as? MessageCell
                    {
                        let item = self.viewModel.items[indexPath.row]
                        messageCell.configureTicks(item: item)
                    }
                }
            case let .loading(isLoading):
                if isLoading {
                    self.spinner.startAnimating()
                    self.spinner.isHidden = false
                } else {
                    self.spinner.stopAnimating()
                    self.spinner.isHidden = true
                }
            case .finishedRecording:
                if let playbackView = self.activeControl as? ChatPlaybackView {
                    playbackView.animateOut {
                        self.animateToRecordButtonView()
                    }
                } else {
                    self.animateToRecordButtonView()
                }
            case let .editingDiscarded(itemToReturnTo):
                guard let playbackView = self.activeControl as? ChatPlaybackView else {
                    return
                }
                
                playbackView.configure(audioItem: itemToReturnTo)
            case .leftChat:
                self.delegate?.chatViewControllerDidTapBack(self)
            }
        }
    }
    
    private func toggleEmptyView() {
        if viewModel.shouldShowEmptyView {
            emptyView.isHidden = false
        } else {
            emptyView.isHidden = true
        }
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
        animateToPlaybackView(item: item.withoutStagingPath())
    }
    
    func quickRecordViewControllerDidCancel(_ viewController: QuickRecordViewController) {
        viewController.view.removeFromSuperview()
        viewController.removeFromParent()
        viewController.willMove(toParent: nil)
    }
}

extension ChatViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let scrollPosition = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let scrollViewHeight = scrollView.frame.height
        
        if contentHeight - scrollPosition <= scrollViewHeight {
            viewModel.loadMoreMessages()
        }
    }
}

// MARK: Datasource methods
extension ChatViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        viewModel.items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! MessageCell
        let cellModel = viewModel.items[indexPath.row]
        cell.configure(item: cellModel)
        cell.messageDidStartPlaying = { playingCell in
            self.activeAudioManager = playingCell.audioManager
            self.cellStartedPlaying(cell: playingCell, collectionView: collectionView)
        }
        
        cell.messageDidStopPlaying = { stoppingCell in
            self.activeAudioManager = nil
            self.cellStoppedPlaying(cell: stoppingCell, collectionView: collectionView)
        }
        
        cell.longPressTapped = { message in
            self.presentMessageOptions(message: message)
        }
        
        cell.contentView.transform = CGAffineTransform(scaleX: 1, y: -1)
        return cell
    }
    
    private func presentMessageOptions(message: Message) {
        guard let currentUserId = viewModel.currentUserId, message.chatter.id == currentUserId else {
            return
        }
        
        let alert = UIAlertController(title: "Message options", message: nil, preferredStyle: .actionSheet)
        let delete = UIAlertAction(title: "Delete message", style: .destructive) { _ in
            self.deleteMessage(message: message)
        }
        
        let favourite = UIAlertAction(title: "Add to favourites", style: .default) { _ in
            self.viewModel.toggleFavourite(on: message)
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(delete)
        alert.addAction(favourite)
        alert.addAction(cancel)
        present(alert, animated: true, completion: nil)
    }
    
    private func deleteMessage(message: Message) {
        let alert = UIAlertController(
            title: "Are you sure?",
            message: "Deleting this message will permanently remove it, are you sure you want to delete?",
            preferredStyle: .alert
        )
        
        let delete = UIAlertAction(title: "Delete", style: .destructive) { _ in
            self.viewModel.deleteMessage(message: message)
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(delete)
        alert.addAction(cancel)
        present(alert, animated: true, completion: nil)
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

// MARK: CView layout
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
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAt section: Int
    ) -> UIEdgeInsets {
        UIEdgeInsets(top: 16.0, left: 0, bottom: 16.0, right: 0)
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
