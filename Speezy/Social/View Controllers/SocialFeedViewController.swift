//
//  SocialFeedViewController.swift
//  Speezy
//
//  Created by Matt Beaney on 27/07/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import UIKit

class SocialFeedViewController: UIViewController {
    private var pageViewController: UIPageViewController?
    
    var viewModel = SocialFeedViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configurePageViewController()
        observeViewModelChanges()
        viewModel.loadData()
    }
    
    private func observeViewModelChanges() {
        viewModel.didChange = { change in
            DispatchQueue.main.async {
                switch change {
                case .initialLoad:
                    self.refreshViewControllers()
                case .updated:
                    break
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
            [playbackViewController(post: firstPost)],
            direction: .forward,
            animated: false,
            completion: nil
        )
    }
}

extension SocialFeedViewController: UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard
            let postViewController = viewController as? PlaybackViewController,
            let nextPost = viewModel.post(after: postViewController.viewModel.post)
        else {
            return nil
        }
        
        return self.playbackViewController(post: nextPost)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard
            let postViewController = viewController as? PlaybackViewController,
            let previousPost = viewModel.post(before: postViewController.viewModel.post)
        else {
            return nil
        }
        
        return self.playbackViewController(post: previousPost)
    }
    
    private func playbackViewController(post: Post) -> PlaybackViewController {
        let newViewModel = PlaybackViewModel(post: post)
        let storyboard = UIStoryboard(name: "Social", bundle: nil)
        let newViewController = storyboard.instantiateViewController(
            identifier: "PlaybackViewController"
        ) as! PlaybackViewController
        
        newViewController.viewModel = newViewModel
        return newViewController
    }
}
