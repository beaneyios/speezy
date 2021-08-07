//
//  CommentsViewController.swift
//  Speezy
//
//  Created by Matt Beaney on 10/07/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import UIKit
import TTGSnackbar

class CommentsViewController: UIViewController {
    @IBOutlet weak var sendCommentContainer: UIView!
    @IBOutlet weak var commentsTextField: UITextField!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var lblLikes: UILabel!
    @IBOutlet weak var lblComments: UILabel!
    
    var viewModel: CommentsViewModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sendCommentContainer.layer.cornerRadius = sendCommentContainer.frame.width / 2.0
        sendCommentContainer.clipsToBounds = true
        
        commentsTextField.delegate = self
        configureTableView()
        configureLikes()
        configureComments()
        observeViewModel()
    }
    
    @IBAction func like(_ sender: Any) {
        viewModel.like()
    }
    
    private func observeViewModel() {
        viewModel.didChange = { change in
            DispatchQueue.main.async {
                switch change {
                case .updated:
                    self.tableView.reloadData()
                case .loading(_):
                    break
                case .postUpdated:
                    self.configureLikes()
                    self.configureComments()
                }
            }
        }
    }
    
    private func configureComments() {
        self.lblComments.text = "\(viewModel.post.numberOfComments) Comments"
    }
    
    private func configureLikes() {
        let image: UIImage = {
            if self.viewModel.liked {
                return UIImage(named: "liked-button")!
            } else {
                return UIImage(named: "like-button")!
            }
        }()
        
        self.likeButton.setImage(image, for: .normal)
        self.lblLikes.text = "\(viewModel.post.numberOfLikes)"
        
        self.lblLikes.textColor = viewModel.post.numberOfLikes > 0 ? .speezyPurple : .lightGray
        self.likeButton.tintColor = viewModel.post.numberOfLikes > 0 ? .speezyPurple : .lightGray
    }
    
    private func configureTableView() {
        tableView.dataSource = self
        tableView.register(CommentCell.nib, forCellReuseIdentifier: "cell")
    }
    
    @IBAction func submitCommit(_ sender: Any) {
        viewModel.submitComment()
        commentsTextField.text = nil
    }
}

extension CommentsViewController: UITextFieldDelegate {
    func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        guard let textFieldText = textField.text else {
            return true
        }
        
        let nsText = textFieldText as NSString
        let newString = nsText.replacingCharacters(
            in: range,
            with: string
        )
        
        viewModel.updateTypedComment(newString)        
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
