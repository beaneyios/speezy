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
import SafariServices

class WebViewViewController: UIViewController {
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var lblTitle: UILabel!
    
    var titleText: String!
    var path: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        lblTitle.text = titleText
        
        guard
            let htmlUrl = Bundle.main.url(forResource: path, withExtension: "html"),
            let htmlData = try? Data(contentsOf: htmlUrl),
            let htmlString = String(data: htmlData, encoding: .utf8)
        else {
            return
        }
        
        webView.navigationDelegate = self
        webView.loadHTMLString(htmlString, baseURL: nil)
    }
    
    @IBAction func didTapBack(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
}

extension WebViewViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let url = navigationAction.request.url, navigationAction.navigationType == .linkActivated {
            let safari = SFSafariViewController(url: url)
            present(safari, animated: true, completion: nil)
            decisionHandler(.cancel)
            return
        }
        
        decisionHandler(.allow)
    }
}
