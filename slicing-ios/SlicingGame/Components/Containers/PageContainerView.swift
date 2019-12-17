//
//  PageContainerView.swift
//  Container view: layout for the entire page, makes it easier to handle safe areas
//

import UIKit
import UniLayout
import JsonInflator

class PageContainerView: UIView, UniLayoutView, AppEventObserver {

    // --
    // MARK: UniLayout integration
    // --
    
    var layoutProperties = UniLayoutProperties()

    public var visibility: UniVisibility {
        set {
            isHidden = newValue != .visible
            layoutProperties.hiddenTakesSpace = newValue == .invisible
        }
        get {
            if isHidden {
                return layoutProperties.hiddenTakesSpace ? .invisible : .hidden
            }
            return .visible
        }
    }


    // --
    // MARK: Members
    // --
    
    private var contentContainer = FrameContainerView()


    // --
    // MARK: Viewlet integration
    // --
    
    class func viewlet() -> JsonInflatable {
        return ViewletClass()
    }

    private class ViewletClass: JsonInflatable {

        func create() -> Any {
            return PageContainerView()
        }

        func update(convUtil: InflatorConvUtil, object: Any, attributes: [String: Any], parent: Any?, binder: InflatorBinder?) -> Bool {
            if let pageContainer = object as? PageContainerView {
                // Create or update the title bar
                let titleBarResult = ViewletUtil.createSubviewItem(convUtil: convUtil, currentItem: pageContainer.titleBarView, parent: pageContainer, attributes: attributes, subviewItem: attributes["titleBar"], binder: binder)
                if !titleBarResult.isRecycled(index: 0) {
                    pageContainer.titleBarView = titleBarResult.items.first as? UIView
                }
                
                // Create or update the bottom bar
                let bottomBarResult = ViewletUtil.createSubviewItem(convUtil: convUtil, currentItem: pageContainer.bottomBarView, parent: pageContainer, attributes: attributes, subviewItem: attributes["bottomBar"], binder: binder)
                if !bottomBarResult.isRecycled(index: 0) {
                    pageContainer.bottomBarView = bottomBarResult.items.first as? UIView
                }

                // Create or update the background item
                let backgroundItemResult = ViewletUtil.createSubviewItem(convUtil: convUtil, currentItem: pageContainer.backgroundItemView, parent: pageContainer, attributes: attributes, subviewItem: attributes["backgroundItem"], binder: binder)
                if !backgroundItemResult.isRecycled(index: 0) {
                    pageContainer.backgroundItemView = backgroundItemResult.items.first as? UIView
                    pageContainer.backgroundItemView?.clipsToBounds = false
                }

                // Create or update the content items
                ViewletUtil.createSubviews(convUtil: convUtil, container: pageContainer.contentContainer, parent: pageContainer, attributes: attributes, subviewItems: attributes["contentItems"], binder: binder)
                for view in pageContainer.contentContainer.subviews {
                    view.clipsToBounds = false
                }

                // Generic view properties
                ViewletUtil.applyGenericViewAttributes(convUtil: convUtil, view: pageContainer, attributes: attributes)

                // Chain event observer
                if let eventObserver = parent as? AppEventObserver {
                    pageContainer.eventObserver = eventObserver
                }
                return true
            }
            return false
        }

        func canRecycle(convUtil: InflatorConvUtil, object: Any, attributes: [String: Any]) -> Bool {
            return type(of: object) == PageContainerView.self
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
        addSubview(contentContainer)
        contentContainer.clipsToBounds = false
    }


    // --
    // MARK: Manage views
    // --

    var titleBarView: UIView? {
        didSet {
            oldValue?.removeFromSuperview()
            if let titleBarView = titleBarView {
                addSubview(titleBarView)
            }
        }
    }
    
    var bottomBarView: UIView? {
        didSet {
            oldValue?.removeFromSuperview()
            if let bottomBarView = bottomBarView {
                addSubview(bottomBarView)
            }
        }
    }
    
    var backgroundItemView: UIView? {
        didSet {
            oldValue?.removeFromSuperview()
            if let backgroundItemView = backgroundItemView {
                backgroundItemView.clipsToBounds = false
                insertSubview(backgroundItemView, at: 0)
            }
        }
    }

    func addContentItem(view: UIView) {
        view.clipsToBounds = false
        contentContainer.addSubview(view)
    }

    func removeContentItem(view: UIView) {
        if contentContainer.subviews.contains(view) {
            view.removeFromSuperview()
        }
    }

    func removeAllContentItems() {
        for view in contentContainer.subviews {
            view.removeFromSuperview()
        }
    }


    // --
    // MARK: Configurable values
    // --

    weak var eventObserver: AppEventObserver?


    // --
    // MARK: Interaction
    // --
    
    func observedEvent(_ event: AppEvent, sender: Any?) {
        eventObserver?.observedEvent(event, sender: sender)
    }


    // --
    // MARK: Custom layout
    // --
    
    func measuredSize(sizeSpec: CGSize, widthSpec: UniMeasureSpec, heightSpec: UniMeasureSpec) -> CGSize {
        if widthSpec == .exactSize && heightSpec == .exactSize {
            return sizeSpec
        }
        return CGSize.zero
    }

    override func layoutSubviews() {
        // Position title bar
        let statusInset = statusBarHeight()
        var topInset = statusInset
        if let titleBarView = titleBarView {
            // Prepare the bar
            var isNavigationBar = false
            if let navigationBar = titleBarView as? NavigationBarComponent {
                let titleBarHeight = bounds.width > bounds.height ? AppDimensions.landscapeTitleBarHeight : AppDimensions.portraitTitleBarHeight
                navigationBar.statusBarHeight = statusInset
                navigationBar.barContentHeight = titleBarHeight
                topInset += titleBarHeight
                isNavigationBar = true
            }
            
            // Measure and set frame
            let resultSize = UniLayout.measure(view: titleBarView, sizeSpec: CGSize(width: bounds.width, height: bounds.height), parentWidthSpec: .exactSize, parentHeightSpec: .exactSize, forceViewWidthSpec: .exactSize, forceViewHeightSpec: .unspecified)
            UniLayout.setFrame(view: titleBarView, frame: CGRect(x: 0, y: 0, width: resultSize.width, height: resultSize.height))
            if !isNavigationBar {
                topInset = max(topInset, resultSize.height)
            }
        }
        
        // Position bottom bar
        let bottomInset = bottomControlsHeight()
        if let bottomBarView = bottomBarView {
            UniLayout.setFrame(view: bottomBarView, frame: CGRect(x: 0, y: bounds.height - bottomInset, width: bounds.width, height: bottomInset))
        }
        
        // Position background view
        if let backgroundItemView = backgroundItemView {
            // Determine size
            var limitWidth = bounds.width
            var limitHeight = bounds.height
            if let viewLayoutProperties = (backgroundItemView as? UniLayoutView)?.layoutProperties {
                limitWidth -= viewLayoutProperties.margin.left + viewLayoutProperties.margin.right
                limitHeight -= viewLayoutProperties.margin.top + viewLayoutProperties.margin.bottom
            }
            let measuredSize = UniLayout.measure(view: backgroundItemView, sizeSpec: CGSize(width: limitWidth, height: limitHeight), parentWidthSpec: .exactSize, parentHeightSpec: .exactSize, forceViewWidthSpec: .unspecified, forceViewHeightSpec: .unspecified)

            // Set frame
            var x: CGFloat = 0
            var y: CGFloat = 0
            if let viewLayoutProperties = (backgroundItemView as? UniLayoutView)?.layoutProperties {
                x += viewLayoutProperties.margin.left
                y += viewLayoutProperties.margin.top
                x += (bounds.width - viewLayoutProperties.margin.left - viewLayoutProperties.margin.right - measuredSize.width) * viewLayoutProperties.horizontalGravity
                y += (bounds.height - viewLayoutProperties.margin.top - viewLayoutProperties.margin.bottom - measuredSize.height) * viewLayoutProperties.verticalGravity
            }
            UniLayout.setFrame(view: backgroundItemView, frame: CGRect(x: x, y: y, width: measuredSize.width, height: measuredSize.height))
        }

        // Position content container
        UniLayout.setFrame(view: contentContainer, frame: CGRect(x: 0, y: topInset, width: bounds.width, height: bounds.height - topInset - bottomInset))
    }


    // --
    // MARK: Helper
    // --
    
    func statusBarHeight() -> CGFloat {
        if #available(iOS 11.0, *) {
            return safeAreaInsets.top
        } else {
            return min(UIApplication.shared.statusBarFrame.width, UIApplication.shared.statusBarFrame.height)
        }
    }

    func bottomControlsHeight() -> CGFloat {
        if #available(iOS 11.0, *) {
            return safeAreaInsets.bottom
        }
        return 0
    }

}
