//
//  MainViewController.swift
//  Swift_ContainerViewController
//
//  Created by 一木 英希 on 2019/03/14.
//  Copyright © 2019 一木 英希. All rights reserved.
//

import UIKit

class MainViewController: UIViewController {
    
    var pagerTabKind: PagerTabKind?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupNavigationBar()
    }
    
    private func setupNavigationBar() {
        self.navigationItem.title = self.pagerTabKind?.description
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "pagerTabSegue" {
            let controller = segue.destination as! MainPagerTabViewController
            controller.pagerTabKind = self.pagerTabKind
        }
    }

    @IBOutlet weak var headerBaseView: UIView!
}

