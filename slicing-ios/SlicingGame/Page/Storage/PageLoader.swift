//
//  PageLoader.swift
//  Page storage: handles loading of pages from several sources
//

import Foundation
import Alamofire

class PageLoader {
    
    // --
    // MARK: Statics
    // --
    
    private static let forceInternalSyncLoad = true

    
    // --
    // MARK: Members
    // --
    
    private let location: String
    private let entry: String
    private let loadInternal: Bool
    private var loading = false


    // --
    // MARK: Initialization
    // --
    
    init(location: String, serverPrefix: String = "") {
        self.location = serverPrefix + location
        loadInternal = !self.location.contains("://")
        entry = location
    }
    

    // --
    // MARK: Loading
    // --
    
    func load(completion: @escaping (_ page: Page?, _ error: Error?) -> Void) {
        if let page = PageCache.shared.getEntry(cacheKey: entry) {
            completion(page, nil)
        } else if loadInternal {
            loadInternal(completion: { page, error in
                if let page = page {
                    PageCache.shared.storeEntry(cacheKey: self.entry, page: page)
                }
                completion(page, error)
            })
        } else {
            loadOnline(completion: { page, error in
                if let page = page {
                    PageCache.shared.storeEntry(cacheKey: self.entry, page: page)
                }
                completion(page, error)
            })
        }
    }
    
    private func loadOnline(completion: @escaping (_ page: Page?, _ error: Error?) -> Void) {
        if !loadInternal {
            loading = true
            Alamofire.request(location).responseString { response in
                self.loading = false
                if let string = response.value {
                    completion(Page(jsonString: string), nil)
                } else {
                    completion(nil, response.error)
                }
            }
        } else {
            completion(nil, NSError(domain: "Loading mismatch", code: -1))
        }
    }
    
    private func loadInternal(completion: @escaping (_ page: Page?, _ error: Error?) -> Void) {
        if PageLoader.forceInternalSyncLoad {
            let page = self.loadInternalSync()
            completion(page, page == nil ? NSError(domain: "Could not load page", code: -1) : nil)
        } else {
            loading = true
            DispatchQueue.global().async {
                let page = self.loadInternalSync()
                DispatchQueue.main.async {
                    self.loading = false
                    completion(page, page == nil ? NSError(domain: "Could not load page", code: -1) : nil)
                }
            }
        }
    }
    
    func loadInternalSync() -> Page? {
        if loadInternal {
            if let path = Bundle.main.path(forResource: "Pages/" + fileName(file: location), ofType: fileExtension(file: location)) {
                if let jsonData = try? NSData(contentsOfFile: path, options: .mappedIfSafe) as Data {
                    return Page(jsonData: jsonData)
                }
            }
        }
        return nil
    }
    
    private func fileName(file: String) -> String {
        if let index = file.lastIndex(of: ".") {
            return String(file[..<index])
        }
        return file
    }
    
    private func fileExtension(file: String) -> String {
        if let index = file.lastIndex(of: ".") {
            return String(file[index...])
        }
        return ""
    }

}
