//
//  PageCache.swift
//  Page storage: cached loaded page items
//

import Foundation

class PageCache {
    
    // --
    // MARK: Singleton instance
    // --
    
    public static let shared = PageCache()


    // --
    // MARK: Members
    // --
    
    private var entries = [String: Page]()
    

    // --
    // MARK: Cache access
    // --
    
    func hasEntry(cacheKey: String) -> Bool {
        return entries[cacheKey] != nil
    }
    
    func getEntry(cacheKey: String) -> Page? {
        return entries[cacheKey]
    }
    
    func storeEntry(cacheKey: String, page: Page) {
        entries[cacheKey] = page
    }
    
    func removeEntry(cacheKey: String) {
        entries.removeValue(forKey: cacheKey)
    }
    
    func clear() {
        entries = [:]
    }
    
}
