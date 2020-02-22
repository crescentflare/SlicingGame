//
//  ImageView.swift
//  Basic view: an image view
//

import UIKit
import UniLayout
import JsonInflator

enum ImageStretchType: String {
    
    case none = "none"
    case fill = "fill"
    case aspectFit = "aspectFit"
    case aspectCrop = "aspectCrop"
    
    func toContentMode() -> UIView.ContentMode {
        switch self {
        case .fill:
            return .scaleToFill
        case .aspectFit:
            return .scaleAspectFit
        case .aspectCrop:
            return .scaleAspectFill
        case .none:
            return .center
        }
    }

}

class ImageView: UniImageView {
    
    // --
    // MARK: Viewlet integration
    // --

    class func viewlet() -> JsonInflatable {
        return ViewletClass()
    }
    
    private class ViewletClass: JsonInflatable {
        
        func create() -> Any {
            return ImageView()
        }
        
        func update(convUtil: InflatorConvUtil, object: Any, attributes: [String: Any], parent: Any?, binder: InflatorBinder?) -> Bool {
            if let imageView = object as? ImageView {
                // Apply image
                let stretchType = ImageStretchType(rawValue: convUtil.asString(value: attributes["stretchType"]) ?? "") ?? .none
                imageView.internalImageView.contentMode = stretchType.toContentMode()
                imageView.source = ImageSource.fromValue(value: attributes["source"])
                
                // Generic view properties
                ViewletUtil.applyGenericViewAttributes(convUtil: convUtil, view: imageView, attributes: attributes)
                return true
            }
            return false
        }
        
        func canRecycle(convUtil: InflatorConvUtil, object: Any, attributes: [String: Any]) -> Bool {
            return type(of: object) == ImageView.self
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
        clipsToBounds = true
        internalImageView.contentMode = .center
    }
    
    
    // --
    // MARK: Configurable values
    // --
    
    var source: ImageSource? {
        didSet {
            if let source = source {
                source.getImage(completion: { [weak self] image in
                    if self?.source === source {
                        self?.image = image
                    }
                })
            } else {
                image = nil
            }
        }
    }

}
