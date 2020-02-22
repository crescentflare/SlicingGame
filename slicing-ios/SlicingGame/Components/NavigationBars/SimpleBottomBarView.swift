//
//  SimpleBottomBarView.swift
//  Navigation bar: used to colorize the space under the bottom safe area
//

import UIKit
import UniLayout
import JsonInflator

class SimpleBottomBarView: UniView, NavigationBarComponent {

    // --
    // MARK: Viewlet integration
    // --
    
    class func viewlet() -> JsonInflatable {
        return ViewletClass()
    }

    private class ViewletClass: JsonInflatable {

        func create() -> Any {
            return SimpleBottomBarView()
        }

        func update(convUtil: InflatorConvUtil, object: Any, attributes: [String: Any], parent: Any?, binder: InflatorBinder?) -> Bool {
            if let bottomBar = object as? SimpleBottomBarView {
                ViewletUtil.applyGenericViewAttributes(convUtil: convUtil, view: bottomBar, attributes: attributes)
                return true
            }
            return false
        }

        func canRecycle(convUtil: InflatorConvUtil, object: Any, attributes: [String: Any]) -> Bool {
            return type(of: object) == SimpleBottomBarView.self
        }

    }


    // --
    // MARK: Initialization
    // --
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    private func setup() {
        // No implementation
    }


    // --
    // MARK: NavigationBarComponent implementation
    // --
    
    var averageColor: UIColor? {
        get {
            return backgroundColor
        }
    }

    var statusBarHeight: CGFloat = 0
    var barContentHeight: CGFloat = 0

}
