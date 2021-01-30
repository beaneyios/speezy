//
//  CustomTabBarController.swift
//  Speezy
//
//  Created by Matt Beaney on 30/01/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import UIKit
import SnapKit

class CustomTabBarController: UIViewController {
    let scrollView = UIScrollView()
    
    private var latestViewController: UIViewController?
    private var latestTrailing: Constraint?
    
    func setUpScrollView() {
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
    
    func addViewController(viewController: UIViewController) {
        viewController.willMove(toParent: self)
        addChild(viewController)
        scrollView.addSubview(viewController.view)
        
        viewController.view.snp.makeConstraints {
            self.latestTrailing?.deactivate()
            
            if let latestVc = self.latestViewController {
                $0.leading.equalTo(latestVc.view.snp.trailing)
            }
            
            $0.top.equalToSuperview()
            $0.bottom.equalToSuperview()
            self.latestTrailing = $0.trailing.equalToSuperview().constraint
            
        }
    }
}
