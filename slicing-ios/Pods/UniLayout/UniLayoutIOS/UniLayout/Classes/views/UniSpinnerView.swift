//
//  UniSpinnerView.swift
//  UniLayout Pod
//
//  Library view: a spinner animation
//  Extends UIView containing a UIActivityIndicatorView to support properties for UniLayout containers and padding
//

import UIKit

/// A UniLayout enabled UIActivityIndicatorView, adding padding and layout properties
open class UniSpinnerView: UIView, UniLayoutView, UniLayoutPaddedView {

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
    // MARK: Members
    // ---
    
    private var indicatorView = UniNotifyingActivityIndicatorView()

    
    // ---
    // MARK: UIActivityIndicatorView properties
    // ---

    public var activityIndicatorViewStyle: UIActivityIndicatorView.Style {
        get {
            return indicatorView.style
        }
        set {
            indicatorView.style = newValue
        }
    }

    public var hidesWhenStopped: Bool {
        get {
            return indicatorView.hidesWhenStopped
        }
        set {
            indicatorView.hidesWhenStopped = newValue
        }
    }
    
    public var color: UIColor? {
        get {
            return indicatorView.color
        }
        set {
            indicatorView.color = newValue
        }
    }
    
    public var isAnimating: Bool {
        get {
            return indicatorView.isAnimating
        }
    }

    public var internalActivityIndicatorView: UIActivityIndicatorView {
        get {
            return indicatorView
        }
    }

    
    // ---
    // MARK: Initialization
    // ---

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func setup() {
        addSubview(indicatorView)
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
    // MARK: UIActivityIndicatorView methods
    // ---
    
    public func startAnimating() {
        indicatorView.startAnimating()
    }

    public func stopAnimating() {
        indicatorView.stopAnimating()
    }
    

    // ---
    // MARK: Custom layout
    // ---

    open func measuredSize(sizeSpec: CGSize, widthSpec: UniMeasureSpec, heightSpec: UniMeasureSpec) -> CGSize {
        var result = CGSize(width: padding.left + padding.right, height: padding.top + padding.bottom)
        result.width += indicatorView.intrinsicContentSize.width
        result.height += indicatorView.intrinsicContentSize.height
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

    open override func layoutSubviews() {
        UniLayout.setFrame(view: indicatorView, frame: CGRect(x: padding.left, y: padding.top, width: max(0, bounds.width - padding.left - padding.right), height: max(0, bounds.height - padding.top - padding.bottom)))
    }
    
    open override func systemLayoutSizeFitting(_ targetSize: CGSize, withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority, verticalFittingPriority: UILayoutPriority) -> CGSize {
        return measuredSize(sizeSpec: targetSize, widthSpec: horizontalFittingPriority == UILayoutPriority.required ? UniMeasureSpec.limitSize : UniMeasureSpec.unspecified, heightSpec: verticalFittingPriority == UILayoutPriority.required ? UniMeasureSpec.limitSize : UniMeasureSpec.unspecified)
    }
    
    open override var intrinsicContentSize : CGSize {
        return indicatorView.intrinsicContentSize
    }

}

class UniNotifyingActivityIndicatorView: UIActivityIndicatorView {
    
    // ---
    // MARK: Hook layout into style changes
    // ---
    
    override var style: UIActivityIndicatorView.Style {
        didSet {
            UniLayout.setNeedsLayout(view: self)
        }
    }
    
}
