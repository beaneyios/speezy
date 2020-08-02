//
//  PrivacyPolicyViewController.swift
//  Speezy
//
//  Created by Matt Beaney on 02/08/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import Foundation
import WebKit
import UIKit

class PrivacyPolicyViewController: UIViewController {
    @IBOutlet weak var webView: WKWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard
            let htmlUrl = Bundle.main.url(forResource: "privacy-policy", withExtension: "html"),
            let htmlData = try? Data(contentsOf: htmlUrl),
            let htmlString = String(data: htmlData, encoding: .utf8)
        else {
            return
        }
        
        webView.loadHTMLString(htmlString, baseURL: nil)
    }
}
