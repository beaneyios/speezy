//
//  AudioItemCell.swift
//  Speezy
//
//  Created by Matt Beaney on 21/07/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import UIKit
import AFDateHelper

class AudioItemCell: UITableViewCell {

    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var lblDate: UILabel!
    @IBOutlet weak var btnMoreOptions: UIButton!
    @IBOutlet weak var tagContainer: UIView!
    @IBOutlet weak var tagContainerHeight: NSLayoutConstraint!
    
    private var tagsView: TagsView?
    
    func configure(with audioItem: AudioItem) {
        lblTitle.text = audioItem.title
        
        if audioItem.tags.count > 0 {
            tagContainerHeight.constant = 36.5
            configureTags(item: audioItem)
        } else {
            tagContainerHeight.constant = 0.0
            tagsView?.removeFromSuperview()
            tagsView = nil
        }
        
        lblDate.text = audioItem.date.toStringWithRelativeTime(
            strings: [
                RelativeTimeStringType.nowPast: "Just now"
            ]
        )
    }
    
    func configureTags(item: AudioItem) {
        tagsView?.removeFromSuperview()
        tagsView = nil
        
        let tagsView = TagsView.createFromNib()
        tagContainer.addSubview(tagsView)
        
        tagsView.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }
        
        tagsView.configure(
            with: item.tags,
            foreColor: UIColor(named: "speezy-purple")!,
            backColor: .clear,
            scrollDirection: .horizontal,
            showAddTag: false
        )
        self.tagsView = tagsView
    }
    
    @IBAction func moreOptionsTapped(_ sender: Any) {
        print("More options")
    }
}
