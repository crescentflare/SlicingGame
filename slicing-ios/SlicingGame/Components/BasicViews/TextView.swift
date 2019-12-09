//
//  TextView.swift
//  Basic view: a text view
//

import UIKit
import UniLayout
import JsonInflator

enum TextAlignment: String {
    
    case left = "left"
    case center = "center"
    case right = "right"
    
}

class TextView: UniTextView {
    
    // --
    // MARK: Viewlet integration
    // --

    class func viewlet() -> JsonInflatable {
        return ViewletClass()
    }
    
    private class ViewletClass: JsonInflatable {
        
        func create() -> Any {
            return TextView()
        }
        
        func update(convUtil: InflatorConvUtil, object: Any, attributes: [String: Any], parent: Any?, binder: InflatorBinder?) -> Bool {
            if let textView = object as? TextView {
                // Apply text styling
                let fontSize = convUtil.asDimension(value: attributes["textSize"]) ?? AppDimensions.text
                let font = AppFonts.font(withName: convUtil.asString(value: attributes["font"]) ?? "unknown", ofSize: fontSize)
                textView.font = font
                textView.numberOfLines = convUtil.asInt(value: attributes["maxLines"]) ?? 0
                textView.attributedText = nil
                textView.textColor = convUtil.asColor(value: attributes["textColor"]) ?? .text
                
                // Apply text alignment
                let textAlignment = TextAlignment(rawValue: convUtil.asString(value: attributes["textAlignment"]) ?? "") ?? .left
                switch textAlignment {
                case .center:
                    textView.textAlignment = .center
                case .right:
                    textView.textAlignment = .right
                default:
                    textView.textAlignment = .left
                }
                
                // Apply text
                textView.text = convUtil.asString(value: attributes["localizedText"])?.localized() ?? convUtil.asString(value: attributes["text"])
                
                // Generic view properties
                ViewletUtil.applyGenericViewAttributes(convUtil: convUtil, view: textView, attributes: attributes)
                return true
            }
            return false
        }
        
        func canRecycle(convUtil: InflatorConvUtil, object: Any, attributes: [String: Any]) -> Bool {
            return type(of: object) == TextView.self
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
        font = AppFonts.normal.font(ofSize: AppDimensions.text)
        textColor = .text
    }
    
}
