//
//  GameTitleBarView.swift
//  Navigation bar: the title bar for in-game
//

import UIKit
import UniLayout
import JsonInflator

class GameTitleBarView: LinearContainerView {

    // --
    // MARK: Layout resource
    // --
    
    private let layoutFile = "GameTitleBar"


    // --
    // MARK: Bound views
    // --
    
    private var statusUnderlayView: UniView?
    private var contentView: UniView?
    private var titleView: TextView?
    private var dividerView: UniView?


    // --
    // MARK: Viewlet integration
    // --
    
    override class func viewlet() -> JsonInflatable {
        return ViewletClass()
    }

    private class ViewletClass: JsonInflatable {

        func create() -> Any {
            return GameTitleBarView()
        }

        func update(convUtil: InflatorConvUtil, object: Any, attributes: [String: Any], parent: Any?, binder: InflatorBinder?) -> Bool {
            if let titleBar = object as? GameTitleBarView {
                // Apply title
                titleBar.title = convUtil.asString(value: attributes["localizedTitle"])?.localized() ?? convUtil.asString(value: attributes["title"])
                
                // Apply bar styling
                titleBar.showDivider = convUtil.asBool(value: attributes["showDivider"]) ?? false

                // Generic view properties
                ViewletUtil.applyGenericViewAttributes(convUtil: convUtil, view: titleBar, attributes: attributes)
                return true
            }
            return false
        }

        func canRecycle(convUtil: InflatorConvUtil, object: Any, attributes: [String: Any]) -> Bool {
            return type(of: object) == GameTitleBarView.self
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
        // Inflate
        let binder = InflatorDictBinder()
        ViewletUtil.assertInflateOn(view: self, attributes: JsonLoader.shared.attributesFrom(jsonFile: layoutFile), parent: nil, binder: binder)

        // Bind views
        statusUnderlayView = binder.findByReference("statusUnderlay") as? UniView
        contentView = binder.findByReference("content") as? UniView
        titleView = binder.findByReference("title") as? TextView
        dividerView = binder.findByReference("divider") as? UniView
    }


    // --
    // MARK: Configurable values
    // --
    
    var title: String? {
        set {
            titleView?.text = newValue
        }
        get { return titleView?.text }
    }
    
    var showDivider: Bool = false {
        didSet {
            dividerView?.visibility = showDivider ? .visible : .hidden
        }
    }

}
