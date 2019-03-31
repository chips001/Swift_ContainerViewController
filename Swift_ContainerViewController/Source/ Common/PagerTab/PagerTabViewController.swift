//
//  PagerTabViewController.swift
//  Swift_ContainerViewController
//
//  Created by 一木 英希 on 2019/03/21.
//  Copyright © 2019 一木 英希. All rights reserved.
//

import UIKit

protocol PagerTabDataSource {
    var tabViewControllers: [UIViewController] { get }
}

protocol PagerTabDelegate {
    func updateIndicator(fromIndex: Int, toIndex: Int)
}

protocol PagerTabProgressiveDelegate: PagerTabDelegate {
    func updateIndicator(fromIndex: Int, toIndex: Int, progressPercentage: CGFloat, indexWasChange: Bool)
}

class PagerTabViewController: UIViewController {

    var datasource: PagerTabDataSource?
    var delegate: PagerTabDelegate?
    var pagerBehaviour = PagerTabBehaviour.progressive(elasticIndicatorLimit: true)
    
    var currentIndex = 0
    var viewControllers: [UIViewController] = []
    var viewControllersForScrolling: [UIViewController]?
    var isViewRotating = false
    var isViewAppearing = false
    @IBOutlet weak var containerScrollView: UIScrollView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupContainerScrollView()
    }
    
    //https://lab.sonicmoov.com/development/iphone-app-dev/uiviewcontroller-lifecycle/
    override var shouldAutomaticallyForwardAppearanceMethods: Bool { return false }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.isViewAppearing = true
        self.children.forEach { $0.beginAppearanceTransition(true, animated: animated) }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.isViewAppearing = false
        self.children.forEach { $0.endAppearanceTransition() }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.children.forEach { $0.beginAppearanceTransition(false, animated: animated) }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.children.forEach { $0.endAppearanceTransition()}
    }
    
    func setupContainerScrollView() {
        let tmpContainerScrollView = self.containerScrollView ?? {
            let containerScrollView = UIScrollView(frame: CGRect(x: 0, y:0, width: self.view.bounds.width, height: self.view.bounds.height))
            containerScrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            return containerScrollView
        }()
        
        self.containerScrollView = tmpContainerScrollView
        if self.containerScrollView.superview == nil {
            self.view.addSubview(self.containerScrollView)
        }
        
        self.containerScrollView.bounces = true
        self.containerScrollView.alwaysBounceHorizontal = true
        self.containerScrollView.alwaysBounceVertical = false
        self.containerScrollView.scrollsToTop = false
        self.containerScrollView.delegate = self
        self.containerScrollView.showsHorizontalScrollIndicator = false
        self.containerScrollView.showsVerticalScrollIndicator = false
        self.containerScrollView.isPagingEnabled = true
        
        self.reloadViewControllers()
        
        let childViewController = viewControllers[currentIndex]
        self.addChild(childViewController)
        childViewController.view.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        self.containerScrollView.addSubview(childViewController.view)
        childViewController.didMove(toParent: self)
    }
    
    func pageOffsetForChild(at index: Int) -> CGFloat {
        return CGFloat(index) * self.containerScrollView.bounds.width
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.updateIfNeed()
    }
    
    var lastContentOffsetX: CGFloat = 0.0
    
    var swipeDirection: SwipeDirection {
        if self.containerScrollView.contentOffset.x > self.lastContentOffsetX {
            return .left
        } else if self.containerScrollView.contentOffset.x < self.lastContentOffsetX {
            return .right
        }
        return .none
    }
    
    var pageWidth: CGFloat {
        return self.containerScrollView.bounds.width
    }
    
    var scrollPercentage: CGFloat {
        if self.swipeDirection != .right {
            let module = fmod(self.containerScrollView.contentOffset.x >= 0 ? self.containerScrollView.contentOffset.x : self.pageWidth + self.containerScrollView.contentOffset.x, self.pageWidth)
            return (module == 0.0) ? 1.0 : (module / self.pageWidth)
        }
        return 1 - fmod((self.containerScrollView.contentOffset.x >= 0) ? self.containerScrollView.contentOffset.x : self.pageWidth + self.containerScrollView.contentOffset.x, self.pageWidth) / self.pageWidth
    }
    
    func virtualPageFor(contentOffset: CGFloat) -> Int {
        return Int((contentOffset + 1.5 * self.pageWidth) / self.pageWidth) - 1
    }
    
    func pageFor(virtualPage: Int) -> Int {
        if virtualPage < 0 {
            return 0
        }
        if virtualPage > self.viewControllers.count - 1 {
            return self.viewControllers.count - 1
        }
        return virtualPage
    }
    
    private var lastPageSize: CGSize = .zero
    
    func updateContentAndCurrentIndex() {
        if self.lastPageSize.width != self.pageWidth {
            self.containerScrollView.contentOffset = CGPoint(x: self.pageOffsetForChild(at: self.currentIndex), y: 0)
        }
        self.lastPageSize = self.containerScrollView.bounds.size
        
        let pagerViewControllers = self.viewControllersForScrolling ?? self.viewControllers
        self.containerScrollView.contentSize = CGSize(width: self.pageWidth * CGFloat(pagerViewControllers.count), height: 0)
        
        for (index, childController) in pagerViewControllers.enumerated() {
            let pagerOffset = self.pageOffsetForChild(at: index)
            
            if abs(self.containerScrollView.contentOffset.x - pagerOffset) < self.pageWidth {
                if childController.parent != nil {
                    childController.view.frame = CGRect(
                        x: pagerOffset,
                        y: 0,
                        width: self.containerScrollView.bounds.width,
                        height: self.containerScrollView.bounds.height
                    )
                } else {
                    childController.beginAppearanceTransition(true, animated: false)
                    self.addChild(childController)
                    childController.view.frame = CGRect(
                        x: pagerOffset,
                        y: 0,
                        width: self.containerScrollView.bounds.width,
                        height: self.containerScrollView.bounds.height
                    )
                    childController.view.autoresizingMask = [.flexibleHeight, .flexibleWidth]
                    self.containerScrollView.addSubview(childController.view)
                    childController.didMove(toParent: self)
                    childController.endAppearanceTransition()
                }
            } else {
                if childController.parent != nil {
                    childController.beginAppearanceTransition(false, animated: false)
                    childController.willMove(toParent: nil)
                    childController.view.removeFromSuperview()
                    childController.removeFromParent()
                    childController.endAppearanceTransition()
                }
            }
        }
        
        let oldCurrentIndex = self.currentIndex
        let virtualPage = self.virtualPageFor(contentOffset: self.containerScrollView.contentOffset.x)
        let newCurrentIndex = self.pageFor(virtualPage: virtualPage)
        self.currentIndex = newCurrentIndex
        let changeCurrentIndex = newCurrentIndex != oldCurrentIndex
        
        if let progressiveDelegate = self.delegate as? PagerTabProgressiveDelegate, pagerBehaviour.isProgressiveIndicator {
            let (fromIndex, toIndex, scrollPercentage) = self.progressiveIndicatorData(virtualPage)
            progressiveDelegate.updateIndicator(fromIndex: fromIndex, toIndex: toIndex, progressPercentage: scrollPercentage, indexWasChange: changeCurrentIndex)
        } else {
            self.delegate?.updateIndicator(fromIndex: min(oldCurrentIndex, pagerViewControllers.count - 1), toIndex: newCurrentIndex)
        }
    }
    
    private func progressiveIndicatorData(_ virtualPage: Int) -> (Int, Int, CGFloat) {
        let count = self.viewControllers.count
        var fromIndex = self.currentIndex
        var toIndex = self.currentIndex
        let direction = self.swipeDirection
        
        if direction == .left {
            if virtualPage < 0 {
                fromIndex = -1
                toIndex = 0
            } else if virtualPage > count - 1 {
                fromIndex = count - 1
                toIndex = count
            } else {
                if self.scrollPercentage >= 0.5 {
                    fromIndex = max(toIndex - 1, -1)
                } else {
                    toIndex = fromIndex + 1
                }
            }
        } else if direction == .right {
            if virtualPage < 0 {
                fromIndex = 0
                toIndex = -1
            } else if virtualPage > count - 1 {
                fromIndex = count
                toIndex = -1
            } else {
                if self.scrollPercentage > 0.5 {
                    fromIndex = min(toIndex + 1, count)
                } else {
                    toIndex = fromIndex - 1
                }
            }
        }
        
        if pagerBehaviour.isElasticIndicatorLimit {
            return (fromIndex, toIndex, self.scrollPercentage)
        } else {
            let percentage = (toIndex < 0 || toIndex > count - 1 || fromIndex < 0 || fromIndex > count - 1) ? 0.0 : self.scrollPercentage
            if toIndex < 0 {
                toIndex = 0
            }
            if toIndex > count - 1 {
                toIndex = count - 1
            }
            if fromIndex < 0 {
                fromIndex = 0
            }
            if fromIndex > count - 1 {
                fromIndex = count - 1
            }
            return (fromIndex, toIndex, percentage)
        }
    }
    
    func moveToViewController(at index: Int, animated: Bool = true) {
        guard self.isViewLoaded && self.currentIndex != index else {
            return
        }
        if animated && abs(self.currentIndex - index) > 1 {
            var tmpViewControllers = self.viewControllers
            let currentCildVC = self.viewControllers[self.currentIndex]
            let fromIndex = self.currentIndex < index ? index - 1 : index + 1
            let fromCildVC = self.viewControllers[fromIndex]
            tmpViewControllers[fromIndex] = currentCildVC
            tmpViewControllers[self.currentIndex] = fromCildVC
            self.viewControllersForScrolling = tmpViewControllers
            self.containerScrollView.setContentOffset(CGPoint(x: self.pageOffsetForChild(at: fromIndex), y: 0), animated: false)
            (navigationController?.view ?? view)?.isUserInteractionEnabled = false
            self.containerScrollView.setContentOffset(CGPoint(x: self.pageOffsetForChild(at: index),y: 0), animated: true)
        } else {
            (navigationController?.view ?? view)?.isUserInteractionEnabled = !animated
            self.containerScrollView.setContentOffset(CGPoint(x: self.pageOffsetForChild(at: index), y: 0), animated: animated)
        }
    }
    
    func moveTo(viewController: UIViewController, animated: Bool = true) {
        self.moveToViewController(at: self.viewControllers.index(of: viewController)!, animated: animated)
    }
    
    private func reloadViewControllers() {
        guard let dataSource = self.datasource else {
            fatalError("datasource must not be nil")
        }
        self.viewControllers = dataSource.tabViewControllers
        
        guard !viewControllers.isEmpty else {
            fatalError("DataSource's viewControllers should provide at least one child view controller")
        }
    }
    
    func reloadPagerTabView() {
        guard isViewLoaded else { return }
        for childController in self.viewControllers where childController.parent != nil {
            childController.beginAppearanceTransition(false, animated: false)
            childController.willMove(toParent: nil)
            childController.view.removeFromSuperview()
            childController.removeFromParent()
            childController.endAppearanceTransition()
        }
        self.reloadViewControllers()
        if self.currentIndex > self.viewControllers.count - 1 {
            self.currentIndex = self.viewControllers.count - 1
        }
        self.containerScrollView.contentOffset = CGPoint(x: self.pageOffsetForChild(at: self.currentIndex), y: 0)
        self.updateContentAndCurrentIndex()
    }
    
    // MARK: - Orientation
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        self.isViewRotating = true
        coordinator.animate(alongsideTransition: nil) { [weak self] _ in
            guard let me = self else { return }
            me.isViewRotating = false
            me.updateIfNeed()
        }
    }
    
    // MARK: - PagerTabDataSource
    
    var tabViewControllers: [UIViewController] {
        assertionFailure("Sub-class must implement the PagerTabDataSource tabViewControllers method")
        return []
    }
    
    // MARK: - Helpers
    
    private func updateIfNeed() {
        if self.isViewLoaded && !self.lastPageSize.equalTo(self.containerScrollView.bounds.size) {
            self.updateContentAndCurrentIndex()
        }
    }
}

extension PagerTabViewController: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if self.containerScrollView == scrollView {
            self.updateContentAndCurrentIndex()
            self.lastContentOffsetX = scrollView.contentOffset.x
        }
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        if self.containerScrollView == scrollView {
            self.viewControllersForScrolling = nil
            (self.navigationController?.view ?? view)?.isUserInteractionEnabled = true
            self.updateContentAndCurrentIndex()
        }
    }
}
