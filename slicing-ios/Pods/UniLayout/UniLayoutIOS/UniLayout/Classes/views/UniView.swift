//
//  UniView.swift
//  UniLayout Pod
//
//  Library view: a simple view
//  Extends UIView to support properties for UniLayout containers and padding
//

import UIKit

/// A UniLayout enabled UIView, adding padding and layout properties
open class UniView: UIView, UniLayoutView, UniLayoutPaddedView {

    // ---
    // MARK: Layout integration
    // ---

    public var layoutProperties = UniLayoutProperties()
    public var padding = UIEdgeInsets.zero
    
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

    
    // ---
    // MARK: Override variables to update the layout
    // ---
    
    open override var isHidden: Bool {
        didSet {
            UniLayout.setNeedsLayout(view: self)
        }
    }
    
    
    // ---
    // MARK: Custom layout
    // ---
    
    open func measuredSize(sizeSpec: CGSize, widthSpec: UniMeasureSpec, heightSpec: UniMeasureSpec) -> CGSize {
        var result = CGSize(width: padding.left + padding.right, height: padding.top + padding.bottom)
        if widthSpec == .exactSize {
            result.width = sizeSpec.width
        } else if widthSpec == .limitSize {
            result.width = min(result.width, sizeSpec.width)
        }
        if heightSpec == .exactSize {
            result.height = sizeSpec.height
        } else if heightSpec == .limitSize {
            result.height = min(result.height, sizeSpec.height)
        }
        return result
    }

    open override func systemLayoutSizeFitting(_ targetSize: CGSize, withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority, verticalFittingPriority: UILayoutPriority) -> CGSize {
        return measuredSize(sizeSpec: targetSize, widthSpec: horizontalFittingPriority == UILayoutPriority.required ? UniMeasureSpec.limitSize : UniMeasureSpec.unspecified, heightSpec: verticalFittingPriority == UILayoutPriority.required ? UniMeasureSpec.limitSize : UniMeasureSpec.unspecified)
    }
    
}
