//
//  PageViewController.swift
//  View controller: a generic view controller for loading pages
//

import UIKit
import UniLayout
import JsonInflator

class PageViewController: UIViewController, PageLoaderDelegate, AppEventObserver {

    // --
    // MARK: Members
    // --
    
    var binder: InflatorDictBinder?
    private var modules = [PageModule]()
    private let pageView = PageContainerView()
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

    deinit {
        for module in modules {
            if isResumed {
                module.didPause()
            }
            module.willDestroy()
        }
    }

    
    // --
    // MARK: Lifecycle
    // --
    
    override func loadView() {
        pageView.backgroundColor = .white
        view = pageView
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

        // Resume modules
        for module in modules {
            module.didResume()
        }

        // Check for page updates
        checkPageLoad()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        // Pause modules
        super.viewWillDisappear(animated)
        isResumed = false
        for module in modules {
            module.didPause()
        }

        // Abort page loading
        stopPageLoad()
    }
    
    
    // --
    // MARK: Interaction
    // --

    func observedEvent(_ event: AppEvent, sender: Any?) {
        for module in modules {
            if module.handleEventTypes.contains(event.type) {
                if module.handleEvent(event, sender: sender) {
                    break
                }
            }
        }
    }
    

    // --
    // MARK: Handle status bar
    // --
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        let titleBarColor = (pageView.titleBarView as? NavigationBarComponent)?.averageColor ?? pageView.titleBarView?.backgroundColor
        let checkColor = titleBarColor ?? pageView.backgroundColor
        return checkColor?.intensity() ?? 0 < 0.25 ? .lightContent : .default
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
        if Inflators.viewlet.findInflatableNameInAttributes(inflateLayout) != "pageContainer" {
            var wrappedLayout = page.layout ?? [:]
            if wrappedLayout["width"] == nil {
                wrappedLayout["width"] = "stretchToParent"
            }
            if wrappedLayout["height"] == nil {
                wrappedLayout["height"] = "stretchToParent"
            }
            inflateLayout = [
                "viewlet": "pageContainer",
                "backgroundColor": "#fff",
                "recycling": true,
                "contentItems": [
                    wrappedLayout
                ]
            ]
        }
        binder = InflatorDictBinder()
        ViewletUtil.assertInflateOn(view: pageView, attributes: inflateLayout, binder: binder)
        inflateModules(moduleItems: page.modules)
        pageView.eventObserver = self
        currentPageHash = page.hash
        setNeedsStatusBarAppearanceUpdate()
    }
    
    func didReceivePageLoadingEvent(event: PageLoaderEvent) {
        if event == .loadingFailed {
            pageView.backgroundColor = .red
        }
    }

    private func inflateModules(moduleItems: Any?) {
        // Inflate
        let result = Inflators.module.inflateNestedItemList(currentItems: modules, newItems: moduleItems, enableRecycling: true, parent: self, binder: nil)
        modules.removeAll()
        for item in result.items {
            if let module = item as? PageModule {
                modules.append(module)
            }
        }
        
        // Destroy removed modules
        for removedItem in result.removedItems {
            if let removedModule = removedItem as? PageModule {
                if isResumed {
                    removedModule.didPause()
                }
                removedModule.willDestroy()
            }
        }
        
        // Update new modules if needed
        for index in result.items.indices {
            if let module = result.items[index] as? PageModule, !result.isRecycled(index: index) {
                module.didCreate(viewController: self)
                if isResumed {
                    module.didResume()
                }
            }
        }
    }

}
