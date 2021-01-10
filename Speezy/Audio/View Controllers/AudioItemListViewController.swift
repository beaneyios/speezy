//
//  AudioItemListViewController.swift
//  Speezy
//
//  Created by Matt Beaney on 20/07/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import Foundation
import UIKit
import SCLAlertView

protocol AudioItemListViewControllerDelegate: AnyObject {
    func audioItemListViewController(
        _ viewController: AudioItemListViewController,
        didSelectAudioItem item: AudioItem
    )
    func audioItemListViewControllerDidSelectCreateNewItem(_ viewController: AudioItemListViewController)
    func audioItemListViewControllerDidSelectSettings(_ viewController: AudioItemListViewController)
    func audioItemListViewController(
        _ viewController: AudioItemListViewController,
        didSelectSendOnItem item: AudioItem
    )
    func audioItemListViewControllerDidSelectSignOut(_ viewController: AudioItemListViewController)
}

class AudioItemListViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var btnRecord: UIButton!
    @IBOutlet weak var gradient: UIImageView!
    @IBOutlet weak var emptyView: UIView!
    @IBOutlet weak var profileButton: SpeezyButton!
    
    var shareAlert: SCLAlertView?
    var documentInteractionController: UIDocumentInteractionController?
    
    lazy var shareController = AudioShareController(parentViewController: self)
    let viewModel = AudioItemListViewModel()
    
    weak var delegate: AudioItemListViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        observeViewModelChanges()
        configureTableView()
        loadItems()
        loadProfileImage()
        configureProfileButton()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        profileButton.layer.cornerRadius = profileButton.frame.width / 2.0
        profileButton.clipsToBounds = true
    }
    
    private func configureProfileButton() {
        profileButton.addTarget(self, action: #selector(signOut), for: .touchUpInside)
    }
    
    @objc private func signOut() {
        viewModel.signOut()
    }
    
    private func configureTableView() {
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 91.0, right: 0)
        tableView.estimatedRowHeight = 100.0
        tableView.register(UINib(nibName: "AudioItemCell", bundle: nil), forCellReuseIdentifier: "cell")
        tableView.separatorStyle = .none
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    private func observeViewModelChanges() {
        viewModel.didChange = { change in
            DispatchQueue.main.async {
                switch change {
                case .itemsLoaded:
                    self.toggleEmptyView()
                    self.tableView.reloadData()
                case let .profileImageLoaded(image):
                    self.profileButton.stopLoading(image: image)
                case .userSignedOut:
                    self.delegate?.audioItemListViewControllerDidSelectSignOut(self)
                }
            }
        }
    }
    
    private func loadItems() {
        viewModel.loadItems()
    }
    
    private func loadProfileImage() {
        profileButton.startLoading(
            color: UIColor(named: "speezy-purple") ?? .black,
            style: .medium
        )
        viewModel.loadProfileImage()
    }
    
    private func toggleEmptyView() {
        if viewModel.shouldShowEmptyView {
            emptyView.isHidden = false
        } else {
            emptyView.isHidden = true
        }
    }
    
    @IBAction func signOutTapped(_ sender: Any) {
        signOut()
    }
    
    @IBAction func settingsTapped(_ sender: Any) {
        delegate?.audioItemListViewControllerDidSelectSettings(self)
    }
    
    @IBAction func speezyTapped(_ sender: Any) {
        presentQuickRecordDialogue()
    }
    
    private func presentQuickRecordDialogue() {
        let storyboard = UIStoryboard(name: "Audio", bundle: nil)
        let quickRecordViewController = storyboard.instantiateViewController(identifier: "quick-record") as! QuickRecordViewController
        
        let newItem = viewModel.newItem
        
        let audioManager = AudioManager(item: newItem)
        quickRecordViewController.audioManager = audioManager
        quickRecordViewController.delegate = self
        
        addChild(quickRecordViewController)
        view.addSubview(quickRecordViewController.view)
        
        quickRecordViewController.view.layer.cornerRadius = 10.0
        quickRecordViewController.view.clipsToBounds = true
        quickRecordViewController.view.addShadow()
        
        quickRecordViewController.view.snp.makeConstraints { (make) in
            make.top.equalTo(view.snp.top)
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.bottom.equalTo(view.snp.bottom)
        }
    }
    
    func reloadItem(_ item: AudioItem) {
        viewModel.reloadItem(item)
    }
}

extension AudioItemListViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.numberOfItems
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let audioItem = viewModel.item(at: indexPath)
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") as! AudioItemCell
        cell.configure(
            with: audioItem,
            audioAttachmentManager: viewModel.audioAttachmentManager
        )
        cell.delegate = self
        cell.selectionStyle = .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let audioItem = viewModel.item(at: indexPath)
        delegate?.audioItemListViewController(self, didSelectAudioItem: audioItem)
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let share = UIContextualAction(style: .normal, title: "Send") { (action, view, completionHandler) in
            self.delegate?.audioItemListViewController(
                self,
                didSelectSendOnItem: self.viewModel.item(at: indexPath)
            )
            completionHandler(true)
        }
        
        share.backgroundColor = UIColor(named: "speezy-purple")
        
        let delete = UIContextualAction(style: .destructive, title: "Delete") { (action, view, completionHandler) in
            let item = self.viewModel.item(at: indexPath)
            self.deleteItem(item: item)
            completionHandler(true)
        }
        
        return UISwipeActionsConfiguration(actions: [share, delete])
    }
    
    private func deleteItem(item: AudioItem) {
        let alert = UIAlertController(
            title: "Delete item",
            message: "Are you sure you want to delete this clip? You will not be able to undo this action.",
            preferredStyle: .alert
        )
        
        let deleteAction = UIAlertAction(
            title: "Delete",
            style: .destructive
        ) { _ in
            self.viewModel.deleteItem(item)
        }
        
        let cancelAction = UIAlertAction(
            title: "Cancel",
            style: .cancel,
            handler: nil
        )

        alert.addAction(deleteAction)
        alert.addAction(cancelAction)
        present(alert, animated: true, completion: nil)
    }
}

extension AudioItemListViewController: AudioItemCellDelegate {
    func audioItemCell(_ cell: AudioItemCell, didTapMoreOptionsWithItem item: AudioItem) {
        let alert = UIAlertController(title: "More options", message: nil, preferredStyle: .actionSheet)
        let shareAction = UIAlertAction(title: "Send", style: .default) { (action) in
            self.share(item: item)
        }
        
        let deleteAction = UIAlertAction(
            title: "Delete",
            style: .destructive
        ) { (action) in
            self.deleteItem(item: item)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(shareAction)
        alert.addAction(deleteAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true, completion: nil)
    }
    
    func share(item: AudioItem) {
        delegate?.audioItemListViewController(self, didSelectSendOnItem: item)
    }
}

extension AudioItemListViewController: QuickRecordViewControllerDelegate {
    func quickRecordViewController(_ viewController: QuickRecordViewController, didFinishRecordingItem item: AudioItem) {
        viewController.view.removeFromSuperview()
        viewController.removeFromParent()
        viewController.willMove(toParent: nil)
        
        let originalItem = item.withPath(path: "\(item.id).\(AudioConstants.fileExtension)")
        let audioManager = AudioManager(item: originalItem)
        
        // The recording is done, save the file first.
        // Then we're going to offer the user the chance to
        // update the title and save it again.
        audioManager.save(saveAttachment: false) { (item) in
            self.showTitleAlert(audioManager: audioManager) {
                audioManager.save(saveAttachment: false) { (item) in
                    DispatchQueue.main.async {
                        self.loadItems()
                    }
                }
            }
        }
    }
    
    func quickRecordViewControllerDidClose(_ viewController: QuickRecordViewController) {
        viewController.view.removeFromSuperview()
        viewController.removeFromParent()
        viewController.willMove(toParent: nil)
    }
    
    private func showTitleAlert(audioManager: AudioManager, completion: (() -> Void)? = nil) {
        let appearance = SCLAlertView.SCLAppearance(showCloseButton: false, fieldCornerRadius: 8.0, buttonCornerRadius: 8.0)
        let alert = SCLAlertView(appearance: appearance)
        let textField = alert.addTextField("Add a title?")
        textField.layer.cornerRadius = 12.0
        alert.addButton("Add") {
            guard let text = textField.text else {
                return
            }
            
            audioManager.updateTitle(title: text)
            completion?()
        }
        
        alert.addButton("Not right now") {
            audioManager.discard {
                completion?()
            }
        }
        
        alert.showEdit(
            "Title",
            subTitle: "Add the title for your audio file here",
            closeButtonTitle: "Cancel",
            colorStyle: 0x3B08A0,
            animationStyle: .topToBottom
        )
    }
}
