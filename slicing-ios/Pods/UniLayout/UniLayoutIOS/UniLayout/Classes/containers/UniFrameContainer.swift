//
//  UniFrameContainer.swift
//  UniLayout Pod
//
//  Library container: an overlapping view container
//  Overlaps and aligns views within the container
//

import UIKit

/// A layout container view used for overlapping subviews with optional alignment properties
open class UniFrameContainer: UIView, UniLayoutView, UniLayoutPaddedView {

    // ---
    // MARK: Layout integration
    // ---
    
    public var layoutProperties = UniLayoutProperties()
    open var padding = UIEdgeInsets.zero
    
    open var visibility: UniVisibility {
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
    // MARK: Tap and highlight support
    // ---

    private let touchInsideTolerance: CGFloat = 64
    private var _highlighted = false
    private var _highlightedBackgroundColor: UIColor?
    private var _normalBackgroundColor: UIColor?
    private weak var _tapDelegate: UniTapDelegate?
    
    open var tapDelegate: UniTapDelegate? {
        set {
            _tapDelegate = newValue
            if _tapDelegate == nil {
                isHighlighted = false
            }
        }
        get {
            return _tapDelegate
        }
    }
    
    open var isHighlighted: Bool {
        set {
            _highlighted = newValue
            super.backgroundColor = _highlighted && _highlightedBackgroundColor != nil ? _highlightedBackgroundColor : _normalBackgroundColor
        }
        get {
            return _highlighted
        }
    }
    
    open var highlightedBackgroundColor: UIColor? {
        set {
            _highlightedBackgroundColor = newValue
            super.backgroundColor = _highlighted && _highlightedBackgroundColor != nil ? _highlightedBackgroundColor : _normalBackgroundColor
        }
        get {
            return _highlightedBackgroundColor
        }
    }
    
    open override var backgroundColor: UIColor? {
        didSet {
            _normalBackgroundColor = backgroundColor
        }
    }
    
    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if _tapDelegate != nil {
            if let _ = touches.first {
                isHighlighted = true
                return
            }
        }
        super.touchesBegan(touches, with: event)
    }
    
    open override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if _tapDelegate != nil {
            if let touch = touches.first {
                let position = touch.location(in: self)
                isHighlighted = position.x >= -touchInsideTolerance && position.x < frame.width + touchInsideTolerance && position.y >= -touchInsideTolerance && position.y < frame.height + touchInsideTolerance
                return
            }
        }
        super.touchesMoved(touches, with: event)
    }

    open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if _tapDelegate != nil {
            if let touch = touches.first {
                isHighlighted = false
                let position = touch.location(in: self)
                if position.x >= -touchInsideTolerance && position.x < frame.width + touchInsideTolerance && position.y >= -touchInsideTolerance && position.y < frame.height + touchInsideTolerance {
                    _tapDelegate?.containerTapped(self)
                }
                return
            }
        }
        super.touchesEnded(touches, with: event)
    }
    
    open override func touchesCancelled(_ touches: Set<UITouch>?, with event: UIEvent?) {
        if _tapDelegate != nil {
            if (touches?.first) != nil {
                isHighlighted = false
                return
            }
        }
        super.touchesCancelled(touches ?? Set(), with: event)
    }

 
    // ---
    // MARK: Custom layout
    // ---

    @discardableResult internal func performLayout(sizeSpec: CGSize, widthSpec: UniMeasureSpec, heightSpec: UniMeasureSpec, adjustFrames: Bool) -> CGSize {
        // Determine available size without padding
        var paddedSize = CGSize(width: max(0, sizeSpec.width - padding.left - padding.right), height: max(0, sizeSpec.height - padding.top - padding.bottom))
        var measuredSize = CGSize(width: padding.left, height: padding.top)
        if widthSpec == .unspecified {
            paddedSize.width = 0xFFFFFF
        }
        if heightSpec == .unspecified {
            paddedSize.height = 0xFFFFFF
        }
        
        // Iterate over subviews and measure each one
        var subviewSizes: [CGSize] = []
        for view in subviews {
            // Skip hidden views if they are not part of the layout
            if view.isHidden && !((view as? UniLayoutView)?.layoutProperties.hiddenTakesSpace ?? false) {
                subviewSizes.append(CGSize.zero)
                continue
            }
            
            // Perform measure
            var limitWidth = paddedSize.width
            var limitHeight = paddedSize.height
            if let viewLayoutProperties = (view as? UniLayoutView)?.layoutProperties {
                limitWidth -= viewLayoutProperties.margin.left + viewLayoutProperties.margin.right
                limitHeight -= viewLayoutProperties.margin.top + viewLayoutProperties.margin.bottom
            }
            let result = UniLayout.measure(view: view, sizeSpec: CGSize(width: limitWidth, height: limitHeight), parentWidthSpec: widthSpec, parentHeightSpec: heightSpec, forceViewWidthSpec: .unspecified, forceViewHeightSpec: .unspecified)
            subviewSizes.append(result)
        }
        
        // Start doing layout
        for i in 0..<min(subviews.count, subviewSizes.count) {
            // Skip hidden views if they are not part of the layout
            let view = subviews[i]
            if view.isHidden && !((view as? UniLayoutView)?.layoutProperties.hiddenTakesSpace ?? false) {
                continue
            }
            
            // Continue with the others
            let size = subviewSizes[i]
            var x = padding.left
            var y = padding.top
            if let viewLayoutProperties = (view as? UniLayoutView)?.layoutProperties {
                x += viewLayoutProperties.margin.left
                y += viewLayoutProperties.margin.top
                if adjustFrames {
                    x += (paddedSize.width - viewLayoutProperties.margin.left - viewLayoutProperties.margin.right - size.width) * viewLayoutProperties.horizontalGravity
                    y += (paddedSize.height - viewLayoutProperties.margin.top - viewLayoutProperties.margin.bottom - size.height) * viewLayoutProperties.verticalGravity
                }
                measuredSize.width = max(measuredSize.width, x + size.width + viewLayoutProperties.margin.right)
                measuredSize.height = max(measuredSize.height, y + size.height + viewLayoutProperties.margin.bottom)
            } else {
                measuredSize.width = max(measuredSize.width, x + size.width)
                measuredSize.height = max(measuredSize.height, y + size.height)
            }
            if adjustFrames {
                UniLayout.setFrame(view: view, frame: CGRect(x: x, y: y, width: size.width, height: size.height))
            }
        }
        
        // Adjust final measure with padding and limitations
        measuredSize.width += padding.right
        measuredSize.height += padding.bottom
        if widthSpec == .exactSize {
            measuredSize.width = sizeSpec.width
        } else if widthSpec == .limitSize {
            measuredSize.width = min(measuredSize.width, sizeSpec.width)
        }
        if heightSpec == .exactSize {
            measuredSize.height = sizeSpec.height
        } else if heightSpec == .limitSize {
            measuredSize.height = min(measuredSize.height, sizeSpec.height)
        }
        return measuredSize
    }

    open func measuredSize(sizeSpec: CGSize, widthSpec: UniMeasureSpec, heightSpec: UniMeasureSpec) -> CGSize {
        return performLayout(sizeSpec: sizeSpec, widthSpec: widthSpec, heightSpec: heightSpec, adjustFrames: false)
    }
    
    open override func layoutSubviews() {
        performLayout(sizeSpec: bounds.size, widthSpec: .exactSize, heightSpec: .exactSize, adjustFrames: true)
    }
    
    open override func systemLayoutSizeFitting(_ targetSize: CGSize, withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority, verticalFittingPriority: UILayoutPriority) -> CGSize {
        return measuredSize(sizeSpec: targetSize, widthSpec: horizontalFittingPriority == UILayoutPriority.required ? UniMeasureSpec.limitSize : UniMeasureSpec.unspecified, heightSpec: verticalFittingPriority == UILayoutPriority.required ? UniMeasureSpec.limitSize : UniMeasureSpec.unspecified)
    }
    
    
    // ---
    // MARK: Improve layout needed behavior
    // ---

    open override func willRemoveSubview(_ subview: UIView) {
        UniLayout.setNeedsLayout(view: self)
    }
    
    open override func didAddSubview(_ subview: UIView) {
        UniLayout.setNeedsLayout(view: self)
    }
    
    open override var isHidden: Bool {
        didSet {
            UniLayout.setNeedsLayout(view: self)
        }
    }

}
