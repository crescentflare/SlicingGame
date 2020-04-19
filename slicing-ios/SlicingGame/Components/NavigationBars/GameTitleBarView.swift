//
//  GameTitleBarView.swift
//  Navigation bar: the title bar for in-game
//

import UIKit
import UniLayout
import JsonInflator

class GameTitleBarView: LinearContainerView, NavigationBarComponent {

    // --
    // MARK: Layout resource
    // --
    
    private let layoutFile = "GameTitleBar"


    // --
    // MARK: Bound views
    // --
    
    private var statusUnderlayView: UniView?
    private var contentView: LinearContainerView?
    private var titleView: TextView?
    private var menuButtonView: ImageButtonView?
    private var actionButtonView: ImageButtonView?
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
                
                // Apply icons and events
                titleBar.menuIcon = ImageSource.fromValue(value: attributes["menuIcon"])
                titleBar.menuEvents = AppEvent.fromValues(values: attributes["menuEvents"] ?? attributes["menuEvent"])
                titleBar.actionIcon = ImageSource.fromValue(value: attributes["actionIcon"])
                titleBar.actionEvents = AppEvent.fromValues(values: attributes["actionEvents"] ?? attributes["actionEvent"])

                // Apply bar styling
                titleBar.showDivider = convUtil.asBool(value: attributes["showDivider"]) ?? false

                // Generic view properties
                ViewletUtil.applyGenericViewAttributes(convUtil: convUtil, view: titleBar, attributes: attributes)

                // Chain event observer
                if let eventObserver = parent as? AppEventObserver {
                    titleBar.eventObserver = eventObserver
                }
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
        contentView = binder.findByReference("content") as? LinearContainerView
        titleView = binder.findByReference("title") as? TextView
        menuButtonView = binder.findByReference("menuButton") as? ImageButtonView
        actionButtonView = binder.findByReference("actionButton") as? ImageButtonView
        dividerView = binder.findByReference("divider") as? UniView
    }


    // --
    // MARK: Configurable values
    // --
    
    override var backgroundColor: UIColor? {
        set {
            // Apply color to bar
            statusUnderlayView?.backgroundColor = newValue
            contentView?.backgroundColor = newValue
            
            // Colorize title components
            let titleColor = averageColor?.intensity() ?? 0 < 0.25 ? UIColor.white : UIColor.text
            titleView?.textColor = titleColor
            menuButtonView?.colorize = titleColor
            actionButtonView?.colorize = titleColor
            menuButtonView?.highlightedColorize = titleColor.withAlphaComponent(0.5)
            actionButtonView?.highlightedColorize = titleColor.withAlphaComponent(0.5)
            menuButtonView?.disabledColorize = titleColor.withAlphaComponent(0.25)
            actionButtonView?.disabledColorize = titleColor.withAlphaComponent(0.25)
        }
        get { return statusUnderlayView?.backgroundColor }
    }
    
    var title: String? {
        set {
            titleView?.text = newValue
        }
        get { return titleView?.text }
    }
    
    var menuIcon: ImageSource? {
        set {
            let titlePadding: CGFloat = newValue != nil || actionIcon != nil ? 0 : 16
            menuButtonView?.source = newValue
            menuButtonView?.visibility = newValue != nil || actionIcon != nil ? .visible : .hidden
            actionButtonView?.visibility = newValue != nil || actionIcon != nil ? .visible : .hidden
            titleView?.padding = UIEdgeInsets(top: 0, left: titlePadding, bottom: 0, right: titlePadding)
        }
        get { return menuButtonView?.source }
    }
    
    var menuEvents: [AppEvent] {
        set {
            menuButtonView?.tapEvents = newValue
        }
        get { return menuButtonView?.tapEvents ?? [] }
    }

    var actionIcon: ImageSource? {
        set {
            let titlePadding: CGFloat = newValue != nil || actionIcon != nil ? 0 : 16
            actionButtonView?.source = newValue
            menuButtonView?.visibility = newValue != nil || menuIcon != nil ? .visible : .hidden
            actionButtonView?.visibility = newValue != nil || menuIcon != nil ? .visible : .hidden
            titleView?.padding = UIEdgeInsets(top: 0, left: titlePadding, bottom: 0, right: titlePadding)
        }
        get { return actionButtonView?.source }
    }
    
    var actionEvents: [AppEvent] {
        set {
            actionButtonView?.tapEvents = newValue
        }
        get { return actionButtonView?.tapEvents ?? [] }
    }

    var showDivider: Bool = false {
        didSet {
            dividerView?.visibility = showDivider ? .visible : .hidden
        }
    }
    
    
    // --
    // MARK: NavigationBarComponent implementation
    // --
    
    var averageColor: UIColor? {
        get {
            return statusUnderlayView?.backgroundColor
        }
    }

    var statusBarHeight: CGFloat = 0 {
        didSet {
            statusUnderlayView?.layoutProperties.height = statusBarHeight
        }
    }

    var barContentHeight: CGFloat = 0 {
        didSet {
            contentView?.layoutProperties.height = barContentHeight
            menuButtonView?.layoutProperties.width = barContentHeight
            actionButtonView?.layoutProperties.width = barContentHeight
        }
    }

}
