//
//  UniLinearContainer.swift
//  UniLayout Pod
//
//  Library container: a vertically or horizontally aligned view container
//  Stacks views below or to the right of each other
//

import UIKit

/// Specifies the layout direction of the subviews of the linear container
public enum UniLinearContainerOrientation: String {
    
    case vertical = "vertical"
    case horizontal = "horizontal"
    
}

/// A layout container view used to align subviews horizontally or vertically
open class UniLinearContainer: UIView, UniLayoutView, UniLayoutPaddedView {

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
    // MARK: Members
    // ---
    
    public var orientation = UniLinearContainerOrientation.vertical

    
    // ---
    // MARK: Custom layout
    // ---

    @discardableResult internal func performVerticalLayout(sizeSpec: CGSize, widthSpec: UniMeasureSpec, heightSpec: UniMeasureSpec, adjustFrames: Bool) -> CGSize {
        // Determine available size without padding
        var paddedSize = CGSize(width: max(0, sizeSpec.width - padding.left - padding.right), height: max(0, sizeSpec.height - padding.top - padding.bottom))
        var measuredSize = CGSize(width: padding.left, height: padding.top)
        if widthSpec == .unspecified {
            paddedSize.width = 0xFFFFFF
        }
        if heightSpec == .unspecified {
            paddedSize.height = 0xFFFFFF
        }

        // Determine first sizable view for spacing margin support
        var firstSizableView: UIView?
        for view in subviews {
            if !view.isHidden || ((view as? UniLayoutView)?.layoutProperties.hiddenTakesSpace ?? false) {
                firstSizableView = view
                break
            }
        }

        // Measure the views without any weight
        var subviewSizes: [CGSize] = []
        var totalWeight: CGFloat = 0
        var remainingHeight = paddedSize.height
        var totalMinHeightForWeight: CGFloat = 0
        for view in subviews {
            // Skip hidden views if they are not part of the layout
            if view.isHidden && !((view as? UniLayoutView)?.layoutProperties.hiddenTakesSpace ?? false) {
                subviewSizes.append(CGSize.zero)
                continue
            }

            // Skip views with weight, they will go in the second phase
            if let viewLayoutProperties = (view as? UniLayoutView)?.layoutProperties {
                if viewLayoutProperties.weight > 0 {
                    totalWeight += viewLayoutProperties.weight
                    remainingHeight -= viewLayoutProperties.margin.top + viewLayoutProperties.margin.bottom + viewLayoutProperties.minHeight
                    if view !== firstSizableView {
                        remainingHeight -= viewLayoutProperties.spacingMargin
                    }
                    totalMinHeightForWeight += viewLayoutProperties.minHeight
                    subviewSizes.append(CGSize.zero)
                    continue
                }
            }
            
            // Perform measure and update remaining height
            var limitWidth = paddedSize.width
            if let viewLayoutProperties = (view as? UniLayoutView)?.layoutProperties {
                limitWidth -= viewLayoutProperties.margin.left + viewLayoutProperties.margin.right
                remainingHeight -= viewLayoutProperties.margin.top + viewLayoutProperties.margin.bottom
                if view !== firstSizableView {
                    remainingHeight -= viewLayoutProperties.spacingMargin
                }
            }
            let result = UniLayout.measure(view: view, sizeSpec: CGSize(width: limitWidth, height: remainingHeight), parentWidthSpec: widthSpec, parentHeightSpec: heightSpec, forceViewWidthSpec: .unspecified, forceViewHeightSpec: .unspecified)
            remainingHeight = max(0, remainingHeight - result.height)
            subviewSizes.append(result)
        }
        
        // Measure the remaining views with weight
        remainingHeight += totalMinHeightForWeight
        for i in 0..<min(subviews.count, subviewSizes.count) {
            // Skip hidden views if they are not part of the layout
            let view = subviews[i]
            if view.isHidden && !((view as? UniLayoutView)?.layoutProperties.hiddenTakesSpace ?? false) {
                continue
            }
            
            // Continue with views with weight
            if let viewLayoutProperties = (view as? UniLayoutView)?.layoutProperties {
                if viewLayoutProperties.weight > 0 {
                    let forceViewHeightSpec: UniMeasureSpec = heightSpec == .exactSize ? .exactSize : .unspecified
                    let result = UniLayout.measure(view: view, sizeSpec: CGSize(width: paddedSize.width - viewLayoutProperties.margin.left - viewLayoutProperties.margin.right, height: remainingHeight * viewLayoutProperties.weight / totalWeight), parentWidthSpec: widthSpec, parentHeightSpec: heightSpec, forceViewWidthSpec: .unspecified, forceViewHeightSpec: forceViewHeightSpec)
                    remainingHeight = max(0, remainingHeight - result.height)
                    totalWeight -= viewLayoutProperties.weight
                    subviewSizes[i] = result
                }
            }
        }
        
        // Start doing layout
        var y = padding.top
        for i in 0..<min(subviews.count, subviewSizes.count) {
            // Skip hidden views if they are not part of the layout
            let view = subviews[i]
            if view.isHidden && !((view as? UniLayoutView)?.layoutProperties.hiddenTakesSpace ?? false) {
                continue
            }
            
            // Continue with the others
            let size = subviewSizes[i]
            var x = padding.left
            var nextY = y
            if let viewLayoutProperties = (view as? UniLayoutView)?.layoutProperties {
                x += viewLayoutProperties.margin.left
                y += viewLayoutProperties.margin.top
                if view !== firstSizableView {
                    y += viewLayoutProperties.spacingMargin
                }
                if adjustFrames {
                    x += (paddedSize.width - viewLayoutProperties.margin.left - viewLayoutProperties.margin.right - size.width) * viewLayoutProperties.horizontalGravity
                }
                measuredSize.width = max(measuredSize.width, x + size.width + viewLayoutProperties.margin.right)
                nextY = y + size.height + viewLayoutProperties.margin.bottom
            } else {
                measuredSize.width = max(measuredSize.width, x + size.width)
                nextY = y + size.height
            }
            if adjustFrames {
                UniLayout.setFrame(view: view, frame: CGRect(x: x, y: y, width: size.width, height: size.height))
            }
            measuredSize.height = max(measuredSize.height, nextY)
            y = nextY
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

    @discardableResult internal func performHorizontalLayout(sizeSpec: CGSize, widthSpec: UniMeasureSpec, heightSpec: UniMeasureSpec, adjustFrames: Bool) -> CGSize {
        // Determine available size without padding
        var paddedSize = CGSize(width: max(0, sizeSpec.width - padding.left - padding.right), height: max(0, sizeSpec.height - padding.top - padding.bottom))
        var measuredSize = CGSize(width: padding.left, height: padding.top)
        if widthSpec == .unspecified {
            paddedSize.width = 0xFFFFFF
        }
        if heightSpec == .unspecified {
            paddedSize.height = 0xFFFFFF
        }
        
        // Determine first sizable view for spacing margin support
        var firstSizableView: UIView?
        for view in subviews {
            if !view.isHidden || ((view as? UniLayoutView)?.layoutProperties.hiddenTakesSpace ?? false) {
                firstSizableView = view
                break
            }
        }
        
        // Measure the views without any weight
        var subviewSizes: [CGSize] = []
        var totalWeight: CGFloat = 0
        var remainingWidth = paddedSize.width
        var totalMinWidthForWeight: CGFloat = 0
        for view in subviews {
            // Skip hidden views if they are not part of the layout
            if view.isHidden && !((view as? UniLayoutView)?.layoutProperties.hiddenTakesSpace ?? false) {
                subviewSizes.append(CGSize.zero)
                continue
            }
            
            // Skip views with weight, they will go in the second phase
            if let viewLayoutProperties = (view as? UniLayoutView)?.layoutProperties {
                if viewLayoutProperties.weight > 0 {
                    totalWeight += viewLayoutProperties.weight
                    remainingWidth -= viewLayoutProperties.margin.left + viewLayoutProperties.margin.right + viewLayoutProperties.minWidth
                    if view !== firstSizableView {
                        remainingWidth -= viewLayoutProperties.spacingMargin
                    }
                    totalMinWidthForWeight += viewLayoutProperties.minWidth
                    subviewSizes.append(CGSize.zero)
                    continue
                }
            }
            
            // Perform measure and update remaining width
            var limitHeight = paddedSize.height
            if let viewLayoutProperties = (view as? UniLayoutView)?.layoutProperties {
                remainingWidth -= viewLayoutProperties.margin.left + viewLayoutProperties.margin.right
                limitHeight -= viewLayoutProperties.margin.top + viewLayoutProperties.margin.bottom
                if view !== firstSizableView {
                    remainingWidth -= viewLayoutProperties.spacingMargin
                }
            }
            let result = UniLayout.measure(view: view, sizeSpec: CGSize(width: remainingWidth, height: limitHeight), parentWidthSpec: widthSpec, parentHeightSpec: heightSpec, forceViewWidthSpec: .unspecified, forceViewHeightSpec: .unspecified)
            remainingWidth = max(0, remainingWidth - result.width)
            subviewSizes.append(result)
        }
        
        // Measure the remaining views with weight
        remainingWidth += totalMinWidthForWeight
        for i in 0..<min(subviews.count, subviewSizes.count) {
            // Skip hidden views if they are not part of the layout
            let view = subviews[i]
            if view.isHidden && !((view as? UniLayoutView)?.layoutProperties.hiddenTakesSpace ?? false) {
                continue
            }
            
            // Continue with views with weight
            if let viewLayoutProperties = (view as? UniLayoutView)?.layoutProperties {
                if viewLayoutProperties.weight > 0 {
                    let forceViewWidthSpec: UniMeasureSpec = widthSpec == .exactSize ? .exactSize : .unspecified
                    let result = UniLayout.measure(view: view, sizeSpec: CGSize(width: remainingWidth * viewLayoutProperties.weight / totalWeight, height: paddedSize.height - viewLayoutProperties.margin.top - viewLayoutProperties.margin.bottom), parentWidthSpec: widthSpec, parentHeightSpec: heightSpec, forceViewWidthSpec: forceViewWidthSpec, forceViewHeightSpec: .unspecified)
                    remainingWidth = max(0, remainingWidth - result.width)
                    totalWeight -= viewLayoutProperties.weight
                    subviewSizes[i] = result
                }
            }
        }
        
        // Start doing layout
        var x = padding.left
        for i in 0..<min(subviews.count, subviewSizes.count) {
            // Skip hidden views if they are not part of the layout
            let view = subviews[i]
            if view.isHidden && !((view as? UniLayoutView)?.layoutProperties.hiddenTakesSpace ?? false) {
                continue
            }
            
            // Continue with the others
            let size = subviewSizes[i]
            var y = padding.top
            var nextX = x
            if let viewLayoutProperties = (view as? UniLayoutView)?.layoutProperties {
                x += viewLayoutProperties.margin.left
                y += viewLayoutProperties.margin.top
                if view !== firstSizableView {
                    x += viewLayoutProperties.spacingMargin
                }
                if adjustFrames {
                    y += (paddedSize.height - viewLayoutProperties.margin.top - viewLayoutProperties.margin.bottom - size.height) * viewLayoutProperties.verticalGravity
                }
                measuredSize.height = max(measuredSize.height, y + size.height + viewLayoutProperties.margin.bottom)
                nextX = x + size.width + viewLayoutProperties.margin.right
            } else {
                measuredSize.height = max(measuredSize.height, y + size.height)
                nextX = x + size.width
            }
            if adjustFrames {
                UniLayout.setFrame(view: view, frame: CGRect(x: x, y: y, width: size.width, height: size.height))
            }
            measuredSize.width = max(measuredSize.width, nextX)
            x = nextX
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
        if orientation == .vertical {
            return performVerticalLayout(sizeSpec: sizeSpec, widthSpec: widthSpec, heightSpec: heightSpec, adjustFrames: false)
        }
        return performHorizontalLayout(sizeSpec: sizeSpec, widthSpec: widthSpec, heightSpec: heightSpec, adjustFrames: false)
    }
    
    open override func layoutSubviews() {
        if orientation == .vertical {
            performVerticalLayout(sizeSpec: bounds.size, widthSpec: .exactSize, heightSpec: .exactSize, adjustFrames: true)
        } else {
            performHorizontalLayout(sizeSpec: bounds.size, widthSpec: .exactSize, heightSpec: .exactSize, adjustFrames: true)
        }
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
