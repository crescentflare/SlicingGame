//
//  ViewletUtil.swift
//  Component utility: shared utilities for viewlet integration, also contains the viewlet for a basic view
//

import UIKit
import UniLayout
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
            return UniView()
        }
        
        func update(convUtil: InflatorConvUtil, object: Any, attributes: [String: Any], parent: Any?, binder: InflatorBinder?) -> Bool {
            if let view = object as? UniView {
                ViewletUtil.applyGenericViewAttributes(convUtil: convUtil, view: view, attributes: attributes)
            }
            return true
        }
        
        func canRecycle(convUtil: InflatorConvUtil, object: Any, attributes: [String: Any]) -> Bool {
            return type(of: object) == UniView.self
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
    // MARK: Subview creation
    // --
    
    class func createSubviews(convUtil: InflatorConvUtil, container: UIView, parent: UIView?, attributes: [String: Any], subviewItems: Any?, binder: InflatorBinder?) {
        // Inflate with optional recycling
        let recycling = convUtil.asBool(value: attributes["recycling"]) ?? false
        let result = Inflators.viewlet.inflateNestedItemList(currentItems: container.subviews, newItems: subviewItems, enableRecycling: recycling, parent: parent, binder: binder)

        // First remove items that could not be recycled
        for item in result.removedItems {
            (item as? UIView)?.removeFromSuperview()
        }

        // Process items (non-recycled items are added)
        for index in result.items.indices {
            if let view = result.items[index] as? UIView {
                // Set to container
                if !result.isRecycled(index: index) {
                    container.insertSubview(view, at: index)
                }

                // Bind reference
                if let refId = convUtil.asString(value: result.getAttributes(index: index)["refId"]) {
                    binder?.onBind(refId: refId, object: view)
                }
            }
        }
    }
    
    
    // --
    // MARK: Shared generic view handling
    // --
    
    class func applyGenericViewAttributes(convUtil: InflatorConvUtil, view: UIView, attributes: [String: Any]) {
        // Standard view properties
        let visibility = convUtil.asString(value: attributes["visibility"]) ?? ""
        view.isHidden = visibility == "hidden" || visibility == "invisible"
        view.backgroundColor = convUtil.asColor(value: attributes["backgroundColor"]) ?? UIColor.clear

        // Padding
        if var uniPaddedView = view as? UniLayoutPaddedView {
            let paddingArray = convUtil.asDimensionArray(value: attributes["padding"])
            var defaultPadding: [CGFloat] = [ 0, 0, 0, 0 ]
            if paddingArray.count == 4 {
                defaultPadding = paddingArray
            }
            uniPaddedView.padding = UIEdgeInsets(
                top: convUtil.asDimension(value: attributes["paddingTop"]) ?? defaultPadding[1],
                left: convUtil.asDimension(value: attributes["paddingLeft"]) ?? defaultPadding[0],
                bottom: convUtil.asDimension(value: attributes["paddingBottom"]) ?? defaultPadding[3],
                right: convUtil.asDimension(value: attributes["paddingRight"]) ?? defaultPadding[2])
        }
    }
    
}
