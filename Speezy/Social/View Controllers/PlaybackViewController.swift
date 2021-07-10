//
//  PlaybackViewController.swift
//  Speezy
//
//  Created by Matt Beaney on 10/07/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import UIKit

final class PlaybackViewController: UIViewController {
    
    @IBOutlet weak var imgProfile: UIImageView!
    @IBOutlet weak var playbackSlider: UISlider!
    @IBOutlet weak var lblRemainingTime: UILabel!
    @IBOutlet weak var lblPassedTime: UILabel!
    @IBOutlet weak var playbackButton: UIButton!
    
    @IBOutlet weak var tagsContainer: UIView!
    @IBOutlet weak var commentsContainer: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureCommentsContainer()
        configureTags(
            tags: [
                Tag(id: "Id", title: "Life"),
                Tag(id: "Id", title: "Memories"),
                Tag(id: "Id", title: "Celebrity")
            ]
        )
    }
    
    private func configureTags(tags: [Tag]) {
        let tagsView = TagsView.createFromNib()
        tagsContainer.addSubview(tagsView)
        
        tagsView.snp.makeConstraints { (maker) in
            maker.top.equalToSuperview()
            maker.bottom.equalToSuperview()
            maker.leading.equalToSuperview().offset(16.0)
            maker.trailing.equalToSuperview().offset(-16.0)
        }
        
        tagsView.backgroundColor = .red
        
        tagsView.configure(
            with: tags,
            foreColor: UIColor(named: "speezy-purple")!,
            backColor: .clear,
            scrollDirection: .horizontal,
            showAddTag: false
        )
    }
    
    private func configureCommentsContainer() {
        let storyboard = UIStoryboard(name: "Social", bundle: nil)
        
        let viewController = storyboard.instantiateViewController(identifier: "CommentsViewController")
        viewController.willMove(toParent: self)
        commentsContainer.addSubview(viewController.view)
        viewController.view.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }
        addChild(viewController)
        commentsContainer.addShadow(
            opacity: 0.1,
            radius: 10.0,
            offset: CGSize(width: 0.0, height: -10.0)
        )
        [commentsContainer, viewController.view].forEach {
            $0?.layer.cornerRadius = 25.0
            $0?.layer.maskedCorners = [
                .layerMinXMinYCorner,
                .layerMaxXMinYCorner
            ]
        }
        
    }
}
