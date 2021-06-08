//
//  PreRecordListViewController.swift
//  Speezy
//
//  Created by Matt Beaney on 06/06/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import UIKit

protocol PreRecordListViewControllerDelegate: AnyObject {
    func preRecordListViewController(
        _ viewController: PreRecordListViewController,
        didSelectItem item: AudioItem,
        onOriginalItem preRecordedItem: AudioItem
    )
    
    func preRecordListViewControllerDidTapClose(_ viewController: PreRecordListViewController)
}

class PreRecordListViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    weak var delegate: PreRecordListViewControllerDelegate?
    var viewModel: PreRecordListViewModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureTableView()
        viewModel.didChange = { change in
            DispatchQueue.main.async {
                switch change {
                case .itemsLoaded:
                    self.tableView.reloadData()
                default:
                    break
                }
            }
        }
        
        viewModel.loadItems()
    }
    
    private func configureTableView() {
        tableView.estimatedRowHeight = 100.0
        tableView.register(AudioItemCell.nib, forCellReuseIdentifier: "cell")
        tableView.separatorStyle = .none
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    @IBAction func didTapClose(_ sender: Any) {
        delegate?.preRecordListViewControllerDidTapClose(self)
    }
}

extension PreRecordListViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(
        _ tableView: UITableView,
        numberOfRowsInSection section: Int
    ) -> Int {
        return viewModel.numberOfItems
    }
    
    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        let audioItem = viewModel.item(at: indexPath)
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") as! AudioItemCell
        cell.configure(
            with: audioItem,
            audioAttachmentManager: viewModel.audioAttachmentManager
        )
        
        cell.selectionStyle = .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let audioItem = viewModel.item(at: indexPath)
        delegate?.preRecordListViewController(
            self,
            didSelectItem: audioItem,
            onOriginalItem: viewModel.originalAudioItem
        )
    }
}

extension PreRecordListViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let scrollPosition = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let scrollViewHeight = scrollView.frame.height
        
        if contentHeight - scrollPosition <= scrollViewHeight {
            viewModel.loadMoreItems()
        }
    }
}
