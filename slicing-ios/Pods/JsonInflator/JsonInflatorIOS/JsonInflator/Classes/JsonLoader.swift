//
//  JsonLoader.swift
//  Json inflator Pod
//
//  Library: loading json properties
//  Load JSON and parses it to a dictionary with attributes (to be used for inflation)
//

public class JsonLoader {
    
    // --
    // MARK: Shared instance
    // --

    public static let shared = JsonLoader()
    
    
    // --
    // MARK: Members
    // --

    private var loadedJson = [String: [String: Any]]()
    

    // --
    // MARK: Loading
    // --
    
    public func attributesFrom(jsonFile: String) -> [String: Any]? {
        if let item = loadedJson[jsonFile] {
            return item
        }
        let bundle = Bundle.main
        if let path = bundle.path(forResource: jsonFile, ofType: "json") {
            if let jsonData = try? NSData(contentsOfFile: path, options: .mappedIfSafe) as Data {
                if let json = try? JSONSerialization.jsonObject(with: jsonData, options: .allowFragments) {
                    if let jsonDict = json as? [String: Any] {
                        loadedJson[jsonFile] = jsonDict
                        return jsonDict
                    }
                }
            }
        }
        return nil
    }
    
}
