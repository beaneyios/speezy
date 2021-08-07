//
//  SocialFeedViewController.swift
//  Speezy
//
//  Created by Matt Beaney on 27/07/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import UIKit
import TTGSnackbar

class SocialFeedViewController: UIViewController {
    private var pageViewController: UIPageViewController?
    
    var viewModel = SocialFeedViewModel()
    
    var showRefresh = false
    var isVisible = false
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        isVisible = true
        
        if showRefresh {
            showRefreshNotification()
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        isVisible = false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configurePageViewController()
        observeViewModelChanges()
        viewModel.loadData()
    }
    
    private func showRefreshNotification() {
        let snackbar = TTGSnackbar(
            message: "More posts available",
            duration: .forever,
            actionText: "Refresh",
            actionBlock: { (snackbar) in
                DispatchQueue.main.async {
                    snackbar.dismiss()
                    self.refreshViewControllers()
                }
            }
        )

        snackbar.backgroundColor = .speezyPurple
        snackbar.tintColor = .white
        snackbar.contentInset = UIEdgeInsets(top: 0.0, left: 12.0, bottom: 0.0, right: 6.0)
        snackbar.animationType = .slideFromTopToBottom
        snackbar.show()
        showRefresh = false
    }
    
    private func observeViewModelChanges() {
        viewModel.didChange = { change in
            DispatchQueue.main.async {
                switch change {
                case .initialLoad:
                    self.refreshViewControllers()
                case .updated:
                    break
                case .newPosts:
                    if self.isVisible {
                        self.showRefreshNotification()
                    } else {
                        self.showRefresh = true
                    }
                }
            }            
        }
    }
    
    private func configurePageViewController() {
        let pageViewController = UIPageViewController(
            transitionStyle: .scroll,
            navigationOrientation: .vertical,
            options: nil
        )
        
        pageViewController.dataSource = self
        pageViewController.view.backgroundColor = .white
        
        self.addChild(pageViewController)
        
        pageViewController.willMove(toParent: self)
        self.view.addSubview(pageViewController.view)
        pageViewController.view.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }
        
        pageViewController.didMove(toParent: self)
        self.pageViewController = pageViewController
    }
    
    private func refreshViewControllers() {
        guard let firstPost = viewModel.startPost else {
            return
        }
        
        pageViewController?.setViewControllers(
            [postViewController(post: firstPost)],
            direction: .forward,
            animated: false,
            completion: nil
        )
    }
}

extension SocialFeedViewController: UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard
            let postViewController = viewController as? PostViewController,
            let nextPost = viewModel.post(after: postViewController.viewModel.post)
        else {
            return nil
        }
        
        return self.postViewController(post: nextPost)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard
            let postViewController = viewController as? PostViewController,
            let previousPost = viewModel.post(before: postViewController.viewModel.post)
        else {
            return nil
        }
        
        return self.postViewController(post: previousPost)
    }
    
    private func postViewController(post: Post) -> PostViewController {
        let newViewModel = PostViewModel(post: post)
        let storyboard = UIStoryboard(name: "Social", bundle: nil)
        let newViewController = storyboard.instantiateViewController(
            identifier: "PostViewController"
        ) as! PostViewController
        
        newViewController.viewModel = newViewModel
        return newViewController
    }
}
