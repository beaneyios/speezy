//
//  PlaybackViewController.swift
//  Speezy
//
//  Created by Matt Beaney on 10/07/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import UIKit

final class PlaybackViewController: UIViewController {
    enum DrawState {
        case open
        case closed
    }
    
    @IBOutlet weak var imgProfile: UIImageView!
    @IBOutlet weak var playbackSlider: UISlider!
    @IBOutlet weak var lblRemainingTime: UILabel!
    @IBOutlet weak var lblPassedTime: UILabel!
    @IBOutlet weak var playbackButton: UIButton!
    
    @IBOutlet weak var tagsContainer: UIView!
    @IBOutlet weak var commentsHandleContainer: UIView!
    @IBOutlet weak var commentsHandlePosition: NSLayoutConstraint!
    @IBOutlet weak var commentsContainer: UIView!
    
    var drawState: DrawState = .closed
    
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
                
        tagsView.configure(
            with: tags,
            foreColor: UIColor(named: "speezy-purple")!,
            backColor: .clear,
            scrollDirection: .horizontal,
            showAddTag: false
        )
    }
    
    private func configureCommentsContainer() {
        configureCommentsViewController()
        configureCommentsContainerGestures()
    }
    
    private func configureCommentsViewController() {
        let storyboard = UIStoryboard(name: "Social", bundle: nil)
        
        let viewController = storyboard.instantiateViewController(
            identifier: "CommentsViewController"
        )
        viewController.willMove(toParent: self)
        commentsContainer.addSubview(viewController.view)
        viewController.view.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }
        addChild(viewController)
        commentsHandleContainer.addShadow(
            opacity: 0.1,
            radius: 10.0,
            offset: CGSize(width: 0.0, height: -10.0)
        )
        
        commentsHandleContainer.layer.cornerRadius = 25.0
        commentsHandleContainer.layer.maskedCorners = [
            .layerMinXMinYCorner,
            .layerMaxXMinYCorner
        ]
    }
    
    private func configureCommentsContainerGestures() {
        let pan = UIPanGestureRecognizer(
            target: self,
            action: #selector(commentsHandlePanned(sender:))
        )
        commentsHandleContainer.addGestureRecognizer(pan)
        
        let tap = UITapGestureRecognizer(
            target: self,
            action: #selector(commentsHandleTapped(sender:))
        )
        commentsHandleContainer.addGestureRecognizer(tap)
    }
}

extension PlaybackViewController {
    private var drawClosedPosition: CGFloat { 118.0 }
    private var drawOpenPosition: CGFloat { view.frame.height - 150.0 }
    private var openThreshhold: CGFloat { -125.0 }
    
    private var bottomBounceThreshold: CGFloat { 110.0 }
    private var topBounceThreshold: CGFloat { view.frame.height - 140.0 }
        
    private var basePosition: CGFloat {
        switch drawState {
        case .open: return drawOpenPosition
        case .closed: return drawClosedPosition
        }
    }
    
    private var canMove: Bool {
        let constant = commentsHandlePosition.constant
        return constant >= bottomBounceThreshold && constant <= topBounceThreshold
    }
    
    @objc private func commentsHandleTapped(sender: UITapGestureRecognizer) {
        switch drawState {
        case .open: closeComments()
        case .closed: openComments()
        }
    }
    
    @objc private func commentsHandlePanned(sender: UIPanGestureRecognizer) {
        let translation = sender.translation(in: view)
        
        switch sender.state {
        case .changed:
            if canMove {
                commentsHandlePosition.constant = basePosition - translation.y
                view.layoutIfNeeded()
            }
        case .ended:
            if translation.y < openThreshhold {
                openComments()
            } else {
                closeComments()
            }
        default:
            break
        }
    }
    
    private func openComments() {
        commentsHandlePosition.constant = drawOpenPosition
        drawState = .open
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    private func closeComments() {
        commentsHandlePosition.constant = drawClosedPosition
        drawState = .closed
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
}
