//
//  PageContainerView.swift
//  Container view: layout for the entire page, makes it easier to handle safe areas
//

import UIKit
import UniLayout
import JsonInflator

class PageContainerView: UIView, UniLayoutView {

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
                // Create or update background item
                let backgroundItemResult = ViewletUtil.createSubviewItem(convUtil: convUtil, currentItem: pageContainer.backgroundItemView, parent: pageContainer, attributes: attributes, subviewItem: attributes["backgroundItem"], binder: binder)
                if !backgroundItemResult.isRecycled(index: 0) {
                    pageContainer.backgroundItemView = backgroundItemResult.items.first as? UIView
                    pageContainer.backgroundItemView?.clipsToBounds = false
                }

                // Create or update content items
                ViewletUtil.createSubviews(convUtil: convUtil, container: pageContainer.contentContainer, parent: pageContainer, attributes: attributes, subviewItems: attributes["contentItems"], binder: binder)
                for view in pageContainer.contentContainer.subviews {
                    view.clipsToBounds = false
                }

                // Generic view properties
                ViewletUtil.applyGenericViewAttributes(convUtil: convUtil, view: pageContainer, attributes: attributes)
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
    // MARK: Custom layout
    // --
    
    func measuredSize(sizeSpec: CGSize, widthSpec: UniMeasureSpec, heightSpec: UniMeasureSpec) -> CGSize {
        if widthSpec == .exactSize && heightSpec == .exactSize {
            return sizeSpec
        }
        return CGSize.zero
    }

    override func layoutSubviews() {
        // Position background view
        let topInset = statusBarHeight()
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
        let bottomInset = bottomControlsHeight()
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
