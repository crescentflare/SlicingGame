//
//  LinearContainerView.swift
//  Container view: basic layout container for horizontally or vertically aligned views
//

import UIKit
import UniLayout
import JsonInflator

class LinearContainerView: UniLinearContainer {
    
    // --
    // MARK: Viewlet integration
    // --
    
    class func viewlet() -> JsonInflatable {
        return ViewletClass()
    }
    
    private class ViewletClass: JsonInflatable {
        
        func create() -> Any {
            return LinearContainerView()
        }
        
        func update(convUtil: InflatorConvUtil, object: Any, attributes: [String: Any], parent: Any?, binder: InflatorBinder?) -> Bool {
            if let linearContainer = object as? LinearContainerView {
                // Set orientation
                if let orientation = UniLinearContainerOrientation(rawValue: convUtil.asString(value: attributes["orientation"]) ?? "") {
                    linearContainer.orientation = orientation
                } else {
                    linearContainer.orientation = .vertical
                }
                
                // Create or update subviews
                ViewletUtil.createSubviews(convUtil: convUtil, container: linearContainer, parent: linearContainer, attributes: attributes, subviewItems: attributes["items"], binder: binder)
                
                // Generic view properties
                ViewletUtil.applyGenericViewAttributes(convUtil: convUtil, view: linearContainer, attributes: attributes)
                return true
            }
            return false
        }
        
        func canRecycle(convUtil: InflatorConvUtil, object: Any, attributes: [String: Any]) -> Bool {
            return type(of: object) == LinearContainerView.self
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
