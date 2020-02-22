//
//  PageViewController.swift
//  View controller: a generic view controller
//

import UIKit

class PageViewController: UIViewController {

    // --
    // MARK: Members
    // --
    
    private let pageJson: String


    // --
    // MARK: Initialization
    // --
    
    init(pageJson: String) {
        self.pageJson = pageJson
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    // --
    // MARK: Lifecycle
    // --
    
    override func loadView() {
        view = UIView()
        view.backgroundColor = .green
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let pageLoader = PageLoader(location: pageJson)
        pageLoader.load(completion: { page, error in
            if let layout = page?.layout {
                ViewletUtil.assertInflateOn(view: self.view, attributes: layout)
            } else {
                self.view.backgroundColor = UIColor.red
            }
        })
    }
    
}
