//
//  AudioItemCell.swift
//  Speezy
//
//  Created by Matt Beaney on 21/07/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import UIKit
import AFDateHelper

protocol AudioItemCellDelegate: AnyObject {
    func audioItemCell(_ cell: AudioItemCell, didTapMoreOptionsWithItem item: RemoteAudioItem)
}

class AudioItemCell: UITableViewCell {

    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var lblDate: UILabel!
    @IBOutlet weak var btnMoreOptions: UIButton!
    @IBOutlet weak var imgAttachment: UIImageView!
    
    @IBOutlet weak var tagContainer: UIView!
    @IBOutlet weak var tagContainerHeight: NSLayoutConstraint!
    @IBOutlet weak var imgAttachmentWidth: NSLayoutConstraint!
    
    @IBOutlet weak var containerView: UIView!
    
    weak var delegate: AudioItemCellDelegate?
    
    private var tagsView: TagsView?
    private var audioItem: RemoteAudioItem?
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        containerView.backgroundColor = highlighted ? .systemGray5 : .white
    }
    
    func configure(with audioItem: RemoteAudioItem, audioAttachmentManager: AudioAttachmentManager) {
        self.audioItem = audioItem
        lblTitle.text = audioItem.title != "" ? audioItem.title : "No title"
        
        if let tags = audioItem.tags, tags.count > 0 {
            tagContainerHeight.constant = 36.5
            configureTags(tags: tags)
        } else {
            tagContainerHeight.constant = 0.0
            tagsView?.removeFromSuperview()
            tagsView = nil
        }
        
        lblDate.text = audioItem.date?.toStringWithRelativeTime(
            strings: [
                RelativeTimeStringType.nowPast: "Just now"
            ]
        ) ?? ""
        
        imgAttachment.layer.cornerRadius = 20.0
        
//        audioAttachmentManager.fetchAttachment(forItem: audioItem) { (image) in
//            DispatchQueue.main.async {
//                if image == nil {
//                    self.imgAttachmentWidth.constant = 0.0
//                } else {
//                    self.imgAttachmentWidth.constant = 40.0
//                }
//                
//                UIView.animate(withDuration: 0.3) {
//                    self.layoutIfNeeded()
//                }
//                
//                self.imgAttachment.image = image
//            }
//        }
    }
    
    func configureTags(tags: [Tag]) {
        tagsView?.removeFromSuperview()
        tagsView = nil
        
        let tagsView = TagsView.createFromNib()
        tagContainer.addSubview(tagsView)
        
        tagsView.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }
        
        tagsView.configure(
            with: tags,
            foreColor: UIColor(named: "speezy-purple")!,
            backColor: .clear,
            scrollDirection: .horizontal,
            showAddTag: false
        )
        self.tagsView = tagsView
    }
    
    @IBAction func moreOptionsTapped(_ sender: Any) {
        guard let audioItem = audioItem else {
            assertionFailure("Somehow the audio item is nil")
            return
        }
        
        delegate?.audioItemCell(self, didTapMoreOptionsWithItem: audioItem)
    }
}
