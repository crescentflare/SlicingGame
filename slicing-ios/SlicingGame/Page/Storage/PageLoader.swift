//
//  PageLoader.swift
//  Page storage: handles loading of pages from several sources
//

import Foundation
import Alamofire

protocol PageLoaderDelegate: class {

    func didUpdatePage(page: Page)
    func didReceivePageLoadingEvent(event: PageLoaderEvent)

}

enum PageLoaderEvent {

    case loadingStarted
    case loadingFinished
    case loadingFailed
    case loadingMerged
    case loadingCached
    case receivedNewPageData
    case changedPageData
    case ignoredSamePageData

}

class PageLoader {
    
    // --
    // MARK: Statics
    // --
    
    private static let cacheMinute: TimeInterval = 60
    private static let forceInternalSyncLoad = true
    private static let cacheTimeout = cacheMinute * 5

    
    // --
    // MARK: Members
    // --
    
    private weak var delegate: PageLoaderDelegate?
    private let location: String
    private let entry: String
    private let loadInternal: Bool
    private var loading = false
    private var waiting = false
    private var continuousLoad = false


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
            loadOnline(currentHash: "ignore", completion: { page, error in
                if let page = page {
                    PageCache.shared.storeEntry(cacheKey: self.entry, page: page)
                }
                completion(page, error)
            })
        }
    }
    
    private func loadOnline(currentHash: String, completion: @escaping (_ page: Page?, _ error: Error?) -> Void) {
        if !loadInternal {
            let headers: HTTPHeaders = [
                "X-Mock-Wait-Change-Hash": currentHash
            ]
            loading = true
            Alamofire.request(location, headers: headers).responseString { response in
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
    
    
    // --
    // MARK: Advanced loading with cache and hot reload integration
    // --
    
    func startLoading(completion: PageLoaderDelegate, hotReload: Bool, ignoreCache: Bool = false) {
        var cacheStable = false
        delegate = completion
        continuousLoad = hotReload
        if !ignoreCache {
            if let page = PageCache.shared.getEntry(cacheKey: entry) {
                let expired = Date().timeIntervalSince1970 - page.creationTime >= PageLoader.cacheTimeout
                cacheStable = loadInternal || (!hotReload && !expired)
            }
        }
        if !cacheStable {
            tryNextLoad()
        } else {
            delegate?.didReceivePageLoadingEvent(event: .loadingCached)
        }
    }

    func stopLoading() {
        delegate = nil
    }

    private func tryNextLoad() {
        if !loading && !waiting && delegate != nil {
            if loadInternal {
                loadInternal(completion: { page, error in
                    if let page = page {
                        self.delegate?.didReceivePageLoadingEvent(event: .loadingFinished)
                        if PageCache.shared.hasEntry(cacheKey: self.entry) {
                            self.delegate?.didReceivePageLoadingEvent(event: .changedPageData)
                        } else {
                            self.delegate?.didReceivePageLoadingEvent(event: .receivedNewPageData)
                        }
                        PageCache.shared.storeEntry(cacheKey: self.entry, page: page)
                        self.delegate?.didUpdatePage(page: page)
                    } else {
                        self.delegate?.didReceivePageLoadingEvent(event: .loadingFailed)
                    }
                })
            } else {
                let hash = PageCache.shared.getEntry(cacheKey: entry)?.hash ?? "unknown"
                loadOnline(currentHash: continuousLoad ? hash : "ignored", completion: { page, error in
                    var waitingTime: Double = 2
                    if error != nil {
                        self.delegate?.didReceivePageLoadingEvent(event: .loadingFailed)
                    } else {
                        self.delegate?.didReceivePageLoadingEvent(event: .loadingFinished)
                        waitingTime = 0.1
                    }
                    if let page = page {
                        if hash != page.hash {
                            if PageCache.shared.hasEntry(cacheKey: self.entry) {
                                self.delegate?.didReceivePageLoadingEvent(event: .changedPageData)
                            } else {
                                self.delegate?.didReceivePageLoadingEvent(event: .receivedNewPageData)
                            }
                            PageCache.shared.storeEntry(cacheKey: self.entry, page: page)
                            self.delegate?.didUpdatePage(page: page)
                        } else {
                            self.delegate?.didReceivePageLoadingEvent(event: .ignoredSamePageData)
                            PageCache.shared.getEntry(cacheKey: self.entry)?.updateCreationTime()
                        }
                    } else if error == nil {
                        self.delegate?.didReceivePageLoadingEvent(event: .ignoredSamePageData)
                    }
                    if self.continuousLoad {
                        self.waiting = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + waitingTime, execute: {
                            self.waiting = false
                            self.tryNextLoad()
                        })
                    }
                })
            }
        } else {
            delegate?.didReceivePageLoadingEvent(event: .loadingMerged)
        }
    }

}
