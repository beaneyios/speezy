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
    func audioItemListViewController(
        _ viewController: AudioItemListViewController,
        didSelectSendOnItem item: AudioItem
    )
    func audioItemListViewControllerDidSelectBack(_ viewController: AudioItemListViewController)
    func audioItemListViewControllerDidFinishRecording(_ viewController: AudioItemListViewController)
}

class AudioItemListViewController: UIViewController, QuickRecordPresenting {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var emptyView: UIView!
    @IBOutlet weak var segmentControl: UISegmentedControl!
    
    var shareAlert: SCLAlertView?
    var documentInteractionController: UIDocumentInteractionController?
    
    lazy var shareController = AudioShareController(parentViewController: self)
    let viewModel = AudioItemListViewModel(store: Store.shared)
    
    weak var delegate: AudioItemListViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        observeViewModelChanges()
        configureTableView()
        loadItems()
        
        let font = UIFont.boldSystemFont(ofSize: 16.0)
        segmentControl.setTitleTextAttributes(
            [NSAttributedString.Key.font: font],
            for: .normal
        )
    }
    
    func saveItem(_ item: AudioItem) {
        viewModel.saveItem(item)
    }
    
    func discardItem(_ item: AudioItem) {
        viewModel.discardItem(item)
    }
    
    @IBAction func segmentControlChanged(_ sender: UISegmentedControl) {
        print(sender.selectedSegmentIndex)
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
                }
            }
        }
    }
    
    private func loadItems() {
        viewModel.loadItems()
    }
    
    private func toggleEmptyView() {
        if viewModel.shouldShowEmptyView {
            emptyView.isHidden = false
        } else {
            emptyView.isHidden = true
        }
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
        handleRecorderDismissed(viewController: viewController)
        
        let originalItem = item.withPath(path: "\(item.id).\(AudioConstants.fileExtension)")
        let audioManager = AudioManager(item: originalItem)
        audioManager.save(saveAttachment: false) { (result) in
            DispatchQueue.main.async {
                switch result {
                case let .success(item):
                    self.loadItems()
                    self.delegate?.audioItemListViewController(self, didSelectSendOnItem: item)
                case .failure:
                    break
                }
            }
        }
    }
    
    func quickRecordViewControllerDidCancel(_ viewController: QuickRecordViewController) {
        handleRecorderDismissed(viewController: viewController)
    }
    
    private func handleRecorderDismissed(viewController: QuickRecordViewController) {
        viewController.view.removeFromSuperview()
        viewController.removeFromParent()
        viewController.willMove(toParent: nil)
        delegate?.audioItemListViewControllerDidFinishRecording(self)
    }
}
