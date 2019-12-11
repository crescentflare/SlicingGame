//
//  ImageSource.swift
//  Component utility: defines the source of an image
//

import UIKit
import UniLayout

enum ImageSourceType: String {
    
    case unknown = "unknown"
    case appInternal = "app"
    
}

class ImageSource {
    
    // --
    // MARK: Members
    // --

    var type = ImageSourceType.unknown
    var name = ""
    

    // --
    // MARK: Factory method
    // --
    
    class func fromValue(value: Any?) -> ImageSource? {
        if let dictionaryValue = value as? [String: Any] {
            return ImageSource(dictionary: dictionaryValue)
        } else if let stringValue = Inflators.viewlet.convUtil.asString(value: value) {
            return ImageSource(string: stringValue)
        }
        return nil
    }

    
    // --
    // MARK: Initialization
    // --
    
    init(string: String) {
        // Extract type from scheme
        var checkString = string
        if let schemeMarker = checkString.range(of: "://") {
            type = ImageSourceType(rawValue: String(checkString[..<schemeMarker.lowerBound])) ?? .unknown
            checkString = String(checkString[schemeMarker.upperBound...])
        }
        
        // Set name to the remaining string
        name = checkString
    }
    
    init(dictionary: [String: Any]) {
        let convUtil = Inflators.viewlet.convUtil
        type = ImageSourceType(rawValue: convUtil.asString(value: dictionary["type"]) ?? "unknown") ?? .unknown
        if let name = convUtil.asString(value: dictionary["name"]) {
            self.name = name
        }
    }

    
    // --
    // MARK: Conversion
    // --

    var uri: String {
        get {
            return "\(type.rawValue)://\(name)"
        }
    }
    
    var dictionary: [String: Any] {
        get {
            return ["type": type.rawValue, "name": name]
        }
    }
    
    
    // --
    // MARK: Obtain image
    // --

    func getImage() -> UIImage? {
        if type == .appInternal {
            let bundle = Bundle(for: ImageSource.self)
            return UIImage(named: name, in: bundle, compatibleWith: nil)
        }
        return nil
    }
    
}
