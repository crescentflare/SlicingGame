//
//  FrameContainerView.swift
//  Container view: basic layout container for overlapping views
//

import UIKit
import UniLayout
import JsonInflator

class FrameContainerView: UniFrameContainer {
    
    // --
    // MARK: Viewlet integration
    // --
    
    class func viewlet() -> JsonInflatable {
        return ViewletClass()
    }
    
    private class ViewletClass: JsonInflatable {
        
        func create() -> Any {
            return FrameContainerView()
        }
        
        func update(convUtil: InflatorConvUtil, object: Any, attributes: [String: Any], parent: Any?, binder: InflatorBinder?) -> Bool {
            if let frameContainer = object as? FrameContainerView {
                // Create or update subviews
                ViewletUtil.createSubviews(convUtil: convUtil, container: frameContainer, parent: frameContainer, attributes: attributes, subviewItems: attributes["items"], binder: binder)
                
                // Generic view properties
                ViewletUtil.applyGenericViewAttributes(convUtil: convUtil, view: frameContainer, attributes: attributes)
                return true
            }
            return false
        }
        
        func canRecycle(convUtil: InflatorConvUtil, object: Any, attributes: [String: Any]) -> Bool {
            return type(of: object) == FrameContainerView.self
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
    
}
