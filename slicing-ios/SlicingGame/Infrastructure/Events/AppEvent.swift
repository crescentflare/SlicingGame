//
//  AppEvent.swift
//  Event system: defines an event with optional parameters
//

class AppEvent {
    
    // --
    // MARK: Members
    // --

    var type = "unknown"
    var parameters = [String: Any]()
    var name = ""


    // --
    // MARK: Factory methods
    // --
    
    class func fromValue(value: Any?) -> AppEvent? {
        if let dictionaryValue = value as? [String: Any] {
            return AppEvent(dictionary: dictionaryValue)
        } else if let stringValue = Inflators.viewlet.convUtil.asString(value: value) {
            return AppEvent(string: stringValue)
        }
        return nil
    }

    class func fromValues(values: Any?) -> [AppEvent] {
        if let valueArray = values as? [Any] {
            var result = [AppEvent]()
            for valueItem in valueArray {
                if let value = fromValue(value: valueItem) {
                    result.append(value)
                }
            }
            return result
        } else if let singleValue = fromValue(value: values) {
            return [singleValue]
        }
        return []
    }

    
    // --
    // MARK: Initialization
    // --
    
    init(string: String) {
        // Extract type from scheme
        var checkString = string
        if let schemeMarker = checkString.range(of: "://") {
            type = String(checkString[..<schemeMarker.lowerBound])
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
        type = convUtil.asString(value: dictionary["type"]) ?? "unknown"
        if let name = convUtil.asString(value: dictionary["name"]) {
            self.name = name
        }
        parameters = dictionary.filter { $0.key != "type" && $0.key != "name" }
    }
    

    // --
    // MARK: Conversion
    // --

    var uri: String {
        get {
            var uri = "\(type)://\(name)"
            if let parameterString = getParameterString() {
                uri += "?" + parameterString
            }
            return uri
        }
    }
    
    var dictionary: [String: Any] {
        get {
            var dictionary: [String: Any] = ["type": type, "name": name]
            for (key, value) in parameters {
                dictionary[key] = value
            }
            return dictionary
        }
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
