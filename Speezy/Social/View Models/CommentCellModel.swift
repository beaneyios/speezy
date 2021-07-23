//
//  CommentCellModel.swift
//  Speezy
//
//  Created by Matt Beaney on 23/07/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import UIKit
import FirebaseStorage

class CommentCellModel {
    let comment: Comment
    private var downloadTask: StorageDownloadTask?
    
    init(comment: Comment) {
        self.comment = comment
    }
    
    func loadImage(completion: @escaping (StorageFetchResult<UIImage>) -> Void) {
        let commenter = comment.commenter
        
        if commenter.profileImageUrl != nil {
            downloadTask?.cancel()
            downloadTask = ProfileImageFetcher().fetchImage(id: commenter.id, completion: completion)
            return
        }
        
        if let character = commenter.displayName.first {
            completion(
                .success(
                    SpeezyProfileViewGenerator.generateProfileImage(
                        character: String(character),
                        color: commenter.color
                    )
                )
            )
            return
        }
    }
}

extension CommentCellModel {
    var commentText: String {
        comment.comment
    }
    
    var displayNameText: String {
        comment.commenter.displayName
    }
    
    var dateText: String {
        let date = comment.date
        return date.relativeTimeString
    }
}
