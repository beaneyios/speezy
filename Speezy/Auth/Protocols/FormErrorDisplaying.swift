//
//  FormErrorDisplaying.swift
//  Speezy
//
//  Created by Matt Beaney on 10/01/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import UIKit

protocol FormErrorDisplaying {
    var fieldDict: [Field: UIView] { get }
    var separators: [UIView] { get }
    var lblErrorMessage: UILabel! { get }
    
    func clearHighlightedFields()
    func highlightErroredFields(error: AuthError)
}

extension FormErrorDisplaying {
    func clearHighlightedFields() {
        lblErrorMessage.text = nil
        separators.forEach {
            $0.backgroundColor = UIColor(named: "speezy-grey-text")
            $0.constraints.forEach {
                if $0.firstAttribute == .height {
                    $0.constant = 0.5
                }
            }
        }
    }
    
    func highlightErroredFields(error: AuthError) {
        if let field = error.field, let separator = fieldDict[field] {
            separator.constraints.forEach {
                if $0.firstAttribute == .height {
                    $0.constant = 2.0
                }
            }
            separator.backgroundColor = .red
        }
    }
}
