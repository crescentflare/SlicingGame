//
//  ViewletUtil.swift
//  Component utility: shared utilities for viewlet integration, also contains the viewlet for a basic view
//

import UIKit
import JsonInflator

class ViewletUtil {
    
    // --
    // MARK: Basic view viewlet
    // --
    
    class func basicViewViewlet() -> JsonInflatable {
        return viewletClass()
    }
    
    private class viewletClass: JsonInflatable {
        
        func create() -> Any {
            return UIView()
        }
        
        func update(convUtil: InflatorConvUtil, object: Any, attributes: [String: Any], parent: Any?, binder: InflatorBinder?) -> Bool {
            if let view = object as? UIView {
                ViewletUtil.applyGenericViewAttributes(convUtil: convUtil, view: view, attributes: attributes)
            }
            return true
        }
        
        func canRecycle(convUtil: InflatorConvUtil, object: Any, attributes: [String: Any]) -> Bool {
            return type(of: object) == UIView.self
        }
        
    }
    
    
    // --
    // MARK: Inflate with assertion
    // --
    
    class func assertInflateOn(view: UIView, attributes: [String: Any]?, parent: UIView? = nil, binder: InflatorBinder? = nil) {
        // Check if attributes are not nil
        assert(attributes != nil, "Attributes are null, load issue?")
        
        // Check viewlet name
        var viewletName: String?
        if attributes != nil {
            viewletName = Inflators.viewlet.findInflatableNameInAttributes(attributes!)
            assert(viewletName != nil, "No viewlet found, JSON structure issue?")
        }
        
        // Check if the viewlet is registered
        if attributes != nil {
            let viewlet = Inflators.viewlet.findInflatableInAttributes(attributes!)
            assert(viewlet != nil, "No viewlet implementation found, registration issue of \(String(describing: viewletName))?")
        }

        // Check result of inflate
        let result = Inflators.viewlet.inflate(onObject: view, attributes: attributes, parent: parent, binder: binder)
        assert(result == true, "Can't inflate viewlet, class doesn't match with \(String(describing: viewletName))?")
    }
    
    
    // --
    // MARK: Shared generic view handling
    // --
    
    class func applyGenericViewAttributes(convUtil: InflatorConvUtil, view: UIView, attributes: [String: Any]) {
        view.backgroundColor = convUtil.asColor(value: attributes["backgroundColor"]) ?? UIColor.clear
    }
    
}
