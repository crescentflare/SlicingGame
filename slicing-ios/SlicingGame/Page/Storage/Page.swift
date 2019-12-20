//
//  Page.swift
//  Page storage: a single page item
//

import Foundation

class Page {
    
    // --
    // MARK: Members
    // --
    
    var originalData = [String: Any]()
    var creationTime: TimeInterval = 0
    private var parsedHash: String = "unknown"

    var hash: String {
        get { return parsedHash }
    }
    

    // --
    // MARK: Initialization
    // --
    
    init(jsonString: String) {
        parseString(jsonString: jsonString)
    }
    
    init(jsonData: Data) {
        parseData(jsonData: jsonData)
    }

    init(dictionary: [String: Any], hash: String = "unknown") {
        originalData = dictionary
        parsedHash = hash
        updateCreationTime()
    }


    // --
    // MARK: Parsing
    // --
    
    private func parseString(jsonString: String) {
        parseData(jsonData: jsonString.data(using: .utf8))
    }
    
    private func parseData(jsonData: Data?) {
        var resultHash = "unknown"
        originalData = [:]
        if let jsonData = jsonData {
            if let json = try? JSONSerialization.jsonObject(with: jsonData, options: .allowFragments) {
                if let parsedData = json as? [String: Any] {
                    originalData = parsedData
                    resultHash = jsonData.sha256()
                }
            }
        }
        parsedHash = resultHash
        updateCreationTime()
    }


    // --
    // MARK: State updates
    // --
    
    func updateCreationTime() {
        creationTime = Date().timeIntervalSince1970
    }


    // --
    // MARK: Extract data
    // --
    
    var modules: [[String: Any]]? {
        get {
            return originalData["modules"] as? [[String: Any]]
        }
    }
    
    var layout: [String: Any]? {
        get {
            if let dataSets = originalData["dataSets"] as? [String: Any] {
                return dataSets["layout"] as? [String: Any]
            }
            return nil
        }
    }
    
}
