//
//  CommentsViewController.swift
//  Speezy
//
//  Created by Matt Beaney on 10/07/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import UIKit

class CommentsViewController: UIViewController {
    @IBOutlet weak var sendCommentContainer: UIView!
    @IBOutlet weak var commentsTextField: UITextField!
    @IBOutlet weak var tableView: UITableView!
    
    var viewModel: CommentsViewModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sendCommentContainer.layer.cornerRadius = sendCommentContainer.frame.width / 2.0
        sendCommentContainer.clipsToBounds = true
        
        commentsTextField.delegate = self
        configureTableView()
    }
    
    private func configureTableView() {
        tableView.dataSource = self
        tableView.register(CommentCell.nib, forCellReuseIdentifier: "cell")
    }
    
    @IBAction func submitCommit(_ sender: Any) {
        viewModel.submitComment()
    }
}

extension CommentsViewController: UITextFieldDelegate {
    func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        viewModel.updateTypedComment(string)
        return true
    }
}

extension CommentsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.comments.count
    }
    
    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") as! CommentCell
        let comment = viewModel.comments[indexPath.row]
        cell.configure(
            cellModel: CommentCellModel(comment: comment)
        )
        return cell
    }
}
