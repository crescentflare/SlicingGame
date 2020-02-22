//
//  PageLoader.swift
//  Page storage: handles loading of pages
//

import Foundation

class PageLoader {
    
    // --
    // MARK: Statics
    // --
    
    private static let forceInternalSyncLoad = true

    
    // --
    // MARK: Members
    // --
    
    private let location: String
    private var loading = false


    // --
    // MARK: Initialization
    // --
    
    init(location: String) {
        self.location = location
    }
    

    // --
    // MARK: Loading
    // --
    
    func load(completion: @escaping (_ page: Page?, _ error: Error?) -> Void) {
        if let page = PageCache.shared.getEntry(cacheKey: location) {
            completion(page, nil)
        } else {
            loadInternal(completion: { page, error in
                if let page = page {
                    PageCache.shared.storeEntry(cacheKey: self.location, page: page)
                }
                completion(page, error)
            })
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
        if let path = Bundle.main.path(forResource: "Pages/" + fileName(file: location), ofType: fileExtension(file: location)) {
            if let jsonData = try? NSData(contentsOfFile: path, options: .mappedIfSafe) as Data {
                return Page(jsonData: jsonData)
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
