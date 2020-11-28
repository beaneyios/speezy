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
import Hero

protocol AudioItemListViewControllerDelegate: AnyObject {
    func audioItemListViewController(_ viewController: AudioItemListViewController, didSelectAudioItem item: AudioItem)
    func audioItemListViewControllerDidSelectCreateNewItem(_ viewController: AudioItemListViewController)
    func audioItemListViewControllerDidSelectSettings(_ viewController: AudioItemListViewController)
    func audioItemListViewController(_ viewController: AudioItemListViewController, didSelectSendOnItem item: AudioItem)
}

class AudioItemListViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var btnRecord: UIButton!
    @IBOutlet weak var gradient: UIImageView!
    @IBOutlet weak var emptyView: UIView!
    
    var shareAlert: SCLAlertView?
    var documentInteractionController: UIDocumentInteractionController?
    
    lazy var shareController = AudioShareController(parentViewController: self)
    
    weak var delegate: AudioItemListViewControllerDelegate?
    var audioItems: [AudioItem] = []
    
    private var audioAttachmentManager = AudioAttachmentManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 91.0, right: 0)
        tableView.estimatedRowHeight = 100.0
        tableView.register(UINib(nibName: "AudioItemCell", bundle: nil), forCellReuseIdentifier: "cell")
        tableView.separatorStyle = .none
        tableView.delegate = self
        tableView.dataSource = self
        
        hero.isEnabled = true
        btnRecord.hero.id = "record"
        
        loadItems()
    }
    
    private func loadItems() {
        audioItems = AudioStorage.fetchItems()
        DispatchQueue.main.async {
            self.toggleEmptyView()
            self.tableView.reloadData()
        }        
    }
    
    private func toggleEmptyView() {
        if audioItems.count == 0 {
            emptyView.isHidden = false
        } else {
            emptyView.isHidden = true
        }
    }
    
    @IBAction func settingsTapped(_ sender: Any) {
        delegate?.audioItemListViewControllerDidSelectSettings(self)
    }
    
    @IBAction func speezyTapped(_ sender: Any) {
//        delegate?.audioItemListViewControllerDidSelectCreateNewItem(self)
        
        presentQuickRecordDialogue()
    }
    
    private func presentQuickRecordDialogue() {
        let storyboard = UIStoryboard(name: "Audio", bundle: nil)
        let quickRecordViewController = storyboard.instantiateViewController(identifier: "quick-record") as! QuickRecordViewController
        
        let id = UUID().uuidString
        let item = AudioItem(
            id: id,
            path: "\(id).wav",
            title: "",
            date: Date(),
            tags: []
        )
        
        let audioManager = AudioManager(item: item)
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
        if audioItems.contains(item) {
            audioItems = audioItems.replacing(item)
        } else {
            audioItems.append(item)
        }
        
        audioAttachmentManager.resetCache()
        
        DispatchQueue.main.async {
            self.toggleEmptyView()
            self.tableView.reloadData()
        }
    }
}

extension AudioItemListViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        audioItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let audioItem = audioItems[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") as! AudioItemCell
        cell.configure(with: audioItem, audioAttachmentManager: audioAttachmentManager)
        cell.delegate = self
        cell.selectionStyle = .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // transcription-test-file-trimmed
        // supertrimmed
//        let url = Bundle.main.url(forResource: "supertrimmed", withExtension: "flac")
//        let audioItem = AudioItem(id: "Test", path: "test", title: "Test", date: Date(), tags: [], url: url)
//        delegate?.audioItemListViewControllerDidSelectTestSpeechItem(self, item: audioItem)
        
        let audioItem = audioItems[indexPath.row]
        delegate?.audioItemListViewController(self, didSelectAudioItem: audioItem)
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let share = UIContextualAction(style: .normal, title: "Send") { (action, view, completionHandler) in
            self.delegate?.audioItemListViewController(self, didSelectSendOnItem: self.audioItems[indexPath.row])
            completionHandler(true)
        }
        
        share.backgroundColor = UIColor(named: "speezy-purple")
        
        let delete = UIContextualAction(style: .destructive, title: "Delete") { (action, view, completionHandler) in
            let item = self.audioItems[indexPath.row]
            self.deleteItem(item: item) {
                self.audioItems.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .fade)
                self.toggleEmptyView()
            }
            completionHandler(true)
        }
        
        return UISwipeActionsConfiguration(actions: [share, delete])
    }
    
    private func deleteItem(item: AudioItem, completion: @escaping () -> Void) {
        let alert = UIAlertController(
            title: "Delete item",
            message: "Are you sure you want to delete this clip? You will not be able to undo this action.",
            preferredStyle: .alert
        )
        
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { _ in
            self.audioAttachmentManager.storeAttachment(nil, forItem: item, completion: {})
            FileManager.default.deleteExistingURL(item.url)
            AudioStorage.deleteItem(item)
            completion()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            
        }
        
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
        
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { (action) in
            self.deleteItem(item: item, completion: {
                self.audioItems = self.audioItems.removing(item)
                self.tableView.reloadData()
            })
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
        
        let savingController = AudioSavingManager()
        let originalItem = item.withPath(path: "\(item.id).wav")
        
        savingController.saveItem(item: item, originalItem: originalItem)
        audioItems = AudioStorage.fetchItems()
        tableView.reloadData()
        
        let alert = UIAlertController(
            title: "What would you like to do with your recording?",
            message: "You can either save, send, edit or delete, this clip",
            preferredStyle: .alert
        )
        
        let send = UIAlertAction(title: "Send", style: .default) { _ in
            self.delegate?.audioItemListViewController(self, didSelectSendOnItem: item)
        }
        
        let edit = UIAlertAction(title: "Edit", style: .default) { _ in
            self.delegate?.audioItemListViewController(self, didSelectAudioItem: item)
        }
        
        let delete = UIAlertAction(title: "Delete", style: .destructive) { _ in
            self.deleteItem(item: item) {
                self.audioItems = AudioStorage.fetchItems()
                self.tableView.reloadData()
            }
        }
        
        alert.addAction(send)
        alert.addAction(edit)
        alert.addAction(delete)
        present(alert, animated: true, completion: nil)
    }
    
    func quickRecordViewControllerDidClose(_ viewController: QuickRecordViewController) {
        viewController.view.removeFromSuperview()
        viewController.removeFromParent()
        viewController.willMove(toParent: nil)
    }
}
