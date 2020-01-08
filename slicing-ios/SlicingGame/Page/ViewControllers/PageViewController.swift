//
//  PageViewController.swift
//  View controller: a generic view controller
//

import UIKit

class PageViewController: UIViewController {

    // --
    // MARK: Lifecycle
    // --
    
    override func loadView() {
        view = UIView()
        view.backgroundColor = .green
    }
    
}
