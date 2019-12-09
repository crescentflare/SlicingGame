//
//  PageViewController.swift
//  View controller: a generic view controller for loading pages
//

import UIKit
import UniLayout

class PageViewController: UIViewController, PageLoaderDelegate {

    // --
    // MARK: Members
    // --
    
    private let pageJson: String
    private var pageLoader: PageLoader?
    private var pageLoadingServer = ""
    private var currentPageHash = "notset"
    private var isResumed = false


    // --
    // MARK: Initialization
    // --
    
    init(pageJson: String) {
        self.pageJson = pageJson
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    // --
    // MARK: Lifecycle
    // --
    
    override func loadView() {
        view = FrameContainerView()
        view.backgroundColor = .green
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let cachedPage = PageCache.shared.getEntry(cacheKey: pageJson) {
            didUpdatePage(page: cachedPage)
        } else if (!CustomAppConfigManager.currentConfig().devServerUrl.isEmpty && CustomAppConfigManager.currentConfig().pageLoadingMode != .local) || pageJson.contains("://") {
            // Do nothing, wait until viewWillAppear starts the online loading process
        } else {
            let localPageLoader = PageLoader(location: pageJson)
            if let page = localPageLoader.loadInternalSync() {
                PageCache.shared.storeEntry(cacheKey: pageJson, page: page)
                didUpdatePage(page: page)
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // Update the page if it was changed in the background
        super.viewWillAppear(animated)
        isResumed = true
        if let cachedPage = PageCache.shared.getEntry(cacheKey: pageJson) {
            if cachedPage.hash != currentPageHash {
                didUpdatePage(page: cachedPage)
            }
        }

        // Check for page updates
        checkPageLoad()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        isResumed = false
        stopPageLoad()
    }
    
    
    // --
    // MARK: Page loader integration
    // --
    
    private func checkPageLoad() {
        // Refresh page loader instance when the loading mode has changed (which will also drop the cache entry)
        var dropCache = false
        if !pageJson.contains("://") {
            let currentPageLoadingServer = pageLoadingServer
            if !CustomAppConfigManager.currentConfig().devServerUrl.isEmpty && CustomAppConfigManager.currentConfig().pageLoadingMode != .local {
                pageLoadingServer = CustomAppConfigManager.currentConfig().devServerUrl
                if !pageLoadingServer.hasPrefix("http") {
                    pageLoadingServer = "http://\(pageLoadingServer)"
                }
                pageLoadingServer = "\(pageLoadingServer)/pages/"
            } else {
                pageLoadingServer = ""
            }
            dropCache = pageLoadingServer != currentPageLoadingServer && pageLoader != nil
            if dropCache {
                PageCache.shared.removeEntry(cacheKey: pageJson)
            }
        }
        if pageLoader == nil || dropCache {
            pageLoader = PageLoader(location: pageJson, serverPrefix: pageLoadingServer)
        }

        // Start the page loader (which may load if needed)
        pageLoader?.startLoading(completion: self, hotReload: CustomAppConfigManager.currentConfig().pageLoadingMode == .hotReloadServer)
    }
    
    private func stopPageLoad() {
        pageLoader?.stopLoading()
    }
    
    func didUpdatePage(page: Page) {
        var inflateLayout = page.layout ?? [:]
        if Inflators.viewlet.findInflatableNameInAttributes(inflateLayout) != "frameContainer" {
            var wrappedLayout = page.layout ?? [:]
            if wrappedLayout["width"] == nil {
                wrappedLayout["width"] = "stretchToParent"
            }
            if wrappedLayout["height"] == nil {
                wrappedLayout["height"] = "stretchToParent"
            }
            inflateLayout = [
                "viewlet": "frameContainer",
                "recycling": true,
                "items": [
                    wrappedLayout
                ]
            ]
        }
        ViewletUtil.assertInflateOn(view: self.view, attributes: inflateLayout)
        currentPageHash = page.hash
    }
    
    func didReceivePageLoadingEvent(event: PageLoaderEvent) {
        if event == .loadingFailed {
            view.backgroundColor = .red
        }
    }

}
