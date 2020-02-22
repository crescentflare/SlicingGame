//
//  ImageSource.swift
//  Component utility: defines the source of an image
//

import UIKit
import UniLayout
import AlamofireImage

enum ImageSourceType: String {
    
    case unknown = "unknown"
    case appInternal = "app"
    case online = "http"
    case secureOnline = "https"
    
}

class ImageSource: Equatable {
    
    // --
    // MARK: Members
    // --

    var type = ImageSourceType.unknown
    var parameters = [String: Any]()
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
        
        // Extract parameters
        if let parameterMarker = checkString.range(of: "?") {
            // Get parameter string
            let parameterString = String(checkString[parameterMarker.upperBound...])
            checkString = String(checkString[..<parameterMarker.lowerBound])
            
            // Split into separate parameters and fill dictionary
            let parameterItems = parameterString.split(separator: "&").map(String.init)
            for parameterItem in parameterItems {
                let parameterSet = parameterItem.split(separator: "=").map(String.init)
                if parameterSet.count == 2 {
                    let key = parameterSet[0].urlDecode()
                    parameters[key] = parameterSet[1].urlDecode()
                }
            }
        }
        
        // Finally set name to the remaining string
        name = checkString
    }
    
    init(dictionary: [String: Any]) {
        let convUtil = Inflators.viewlet.convUtil
        type = ImageSourceType(rawValue: convUtil.asString(value: dictionary["type"]) ?? "unknown") ?? .unknown
        if let name = convUtil.asString(value: dictionary["name"]) {
            self.name = name
        }
        parameters = dictionary.filter { $0.key != "type" && $0.key != "name" }
    }

    
    // --
    // MARK: Extract values
    // --

    private var density: CGFloat? {
        return parameters["density"] != nil ? CGFloat(Inflators.viewlet.convUtil.asFloat(value: parameters["density"]) ?? 1.0) : nil
    }

    private var forceWidth: CGFloat? {
        return Inflators.viewlet.convUtil.asDimension(value: parameters["forceWidth"])
    }

    private var forceHeight: CGFloat? {
        return Inflators.viewlet.convUtil.asDimension(value: parameters["forceHeight"])
    }

    
    // --
    // MARK: Conversion
    // --

    var uri: String {
        get {
            var uri = "\(type.rawValue)://\(name)"
            if let parameterString = getParameterString() {
                uri += "?" + parameterString
            }
            return uri
        }
    }
    
    var dictionary: [String: Any] {
        get {
            var dictionary: [String: Any] = ["type": type.rawValue, "name": name]
            for (key, value) in parameters {
                dictionary[key] = value
            }
            return dictionary
        }
    }
    
    
    // --
    // MARK: Obtain image
    // --

    func getImage(completion: @escaping (_ image: UIImage?) -> Void) {
        if type == .appInternal {
            let bundle = Bundle(for: ImageSource.self)
            completion(UIImage(named: name, in: bundle, compatibleWith: nil))
        } else if type == .online || type == .secureOnline {
            if let imageUrl = URL(string: uri) {
                UIImageView.af_sharedImageDownloader.download(URLRequest(url: imageUrl), filter: ImageSourceImageScaler(forceWidth: forceWidth, forceHeight: forceHeight, density: density), completion: { response in
                    completion(response.result.value)
                })
            } else {
                completion(nil)
            }
        } else {
            completion(nil)
        }
    }
    

    // --
    // MARK: Equatable implementation
    // --

    static func == (lhs: ImageSource, rhs: ImageSource) -> Bool {
        return lhs.uri == rhs.uri
    }
    
    
    // --
    // MARK: Helper
    // --

    private func getParameterString(ignoreParams: [String] = []) -> String? {
        if parameters.count > 0 {
            var parameterString = ""
            for key in parameters.keys.sorted() {
                var ignore = false
                for ignoreParam in ignoreParams {
                    if key == ignoreParam {
                        ignore = true
                        break
                    }
                }
                if !ignore, let value = Inflators.viewlet.convUtil.asString(value: parameters[key]) {
                    if parameterString.count > 0 {
                        parameterString += "&"
                    }
                    parameterString += key.urlEncode() + "=" + value.urlEncode()
                }
            }
            if !parameterString.isEmpty {
                return parameterString
            }
        }
        return nil
    }

}

fileprivate struct ImageSourceImageScaler: ImageFilter {
    
    private let forceWidth: CGFloat?
    private let forceHeight: CGFloat?
    private let density: CGFloat?
    
    public init(forceWidth: CGFloat? = nil, forceHeight: CGFloat? = nil, density: CGFloat? = nil) {
        self.forceWidth = forceWidth
        self.forceHeight = forceHeight
        self.density = density
    }
    
    public var filter: (Image) -> Image {
        return { image in
            var newWidth = image.size.width
            var newHeight = image.size.height
            if let forceWidth = self.forceWidth {
                newWidth = forceWidth
                newHeight = self.forceHeight ?? image.size.height * newWidth / image.size.width
            } else if let forceHeight = self.forceHeight {
                newHeight = forceHeight
                newWidth = image.size.width * newHeight / image.size.height
            } else if let density = self.density, density != 0 {
                newWidth = image.size.width * UIScreen.main.scale / density
                newHeight = image.size.height * UIScreen.main.scale / density
            }
            if newWidth > 0 && newHeight > 0 && (newWidth != image.size.width || newHeight != image.size.height) {
                return image.af_imageScaled(to: CGSize(width: newWidth, height: newHeight))
            }
            return image
        }
    }
    
}
