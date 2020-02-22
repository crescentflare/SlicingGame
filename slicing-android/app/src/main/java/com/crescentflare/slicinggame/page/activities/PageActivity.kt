package com.crescentflare.slicinggame.page.activities

import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity
import com.crescentflare.dynamicappconfig.activity.ManageAppConfigActivity
import com.crescentflare.slicinggame.components.containers.FrameContainerView
import com.crescentflare.slicinggame.components.utility.ViewletUtil
import com.crescentflare.slicinggame.infrastructure.appconfig.AppConfigPageLoadingMode
import com.crescentflare.slicinggame.infrastructure.appconfig.CustomAppConfigManager
import com.crescentflare.slicinggame.infrastructure.inflator.Inflators
import com.crescentflare.slicinggame.page.storage.Page
import com.crescentflare.slicinggame.page.storage.PageCache
import com.crescentflare.slicinggame.page.storage.PageLoader
import com.crescentflare.slicinggame.page.storage.PageLoaderListener

/**
 * Activity: a generic activity for loading pages
 */
class PageActivity : AppCompatActivity(), PageLoaderListener {

    // --
    // Statics: new instance
    // --

    companion object {

        private const val pageParam = "page"
        private const val defaultPage = "game.json"

        fun newInstance(context: Context, pageJson: String): Intent {
            val intent = Intent(context, PageActivity::class.java)
            intent.putExtra(pageParam, pageJson)
            return intent
        }

    }


    // --
    // Members
    // --

    private val activityView by lazy { FrameContainerView(this) }
    private var pageJson = ""
    private var pageLoader: PageLoader? = null
    private var pageLoadingServer = ""
    private var currentPageHash = "notset"
    private var isResumed = false


    // --
    // Initialization
    // --

    override fun onCreate(savedInstanceState: Bundle?) {
        // Set initial content view
        super.onCreate(savedInstanceState)
        activityView.setBackgroundColor(Color.GREEN)
        setContentView(activityView)

        // Add long click listener to open app config menu
        activityView.setOnLongClickListener {
            ManageAppConfigActivity.startWithResult(this, 0)
            true
        }

        // Determine page to load
        pageJson = intent.getStringExtra(pageParam) ?: defaultPage

        // Pre-load page if possible
        val cachedPage = PageCache.getEntry(pageJson)
        if (cachedPage != null) {
            onPageUpdated(cachedPage)
        } else if ((CustomAppConfigManager.currentConfig().devServerUrl.isNotEmpty() && CustomAppConfigManager.currentConfig().pageLoadingMode != AppConfigPageLoadingMode.Local) || pageJson.contains("://")) {
            // Do nothing, wait until onResume starts the online loading process
        } else {
            val localPageLoader = PageLoader(this, pageJson)
            val page = localPageLoader.loadInternalSync()
            if (page != null) {
                PageCache.storeEntry(pageJson, page)
                onPageUpdated(page)
            }
        }
    }


    // --
    // Lifecycle
    // --

    override fun onResume() {
        // Update the page if it was changed in the background
        super.onResume()
        isResumed = true
        val cachedPage = PageCache.getEntry(pageJson)
        if (cachedPage != null) {
            if (cachedPage.hash != currentPageHash) {
                onPageUpdated(cachedPage)
            }
        }

        // Check for page updates
        checkPageLoad()
    }

    override fun onPause() {
        super.onPause()
        isResumed = false
        stopPageLoad()
    }


    // --
    // Page loader integration
    // --

    private fun checkPageLoad() {
        // Refresh page loader instance when the loading mode has changed (which will also drop the cache entry)
        var dropCache = false
        if (!pageJson.contains("://")) {
            val currentPageLoadingServer = pageLoadingServer
            if (CustomAppConfigManager.currentConfig().devServerUrl.isNotEmpty() && CustomAppConfigManager.currentConfig().pageLoadingMode != AppConfigPageLoadingMode.Local) {
                pageLoadingServer = CustomAppConfigManager.currentConfig().devServerUrl
                if (!pageLoadingServer.startsWith("http")) {
                    pageLoadingServer = "http://$pageLoadingServer"
                }
                pageLoadingServer = "$pageLoadingServer/pages/"
            } else {
                pageLoadingServer = ""
            }
            dropCache = pageLoadingServer != currentPageLoadingServer && pageLoader != null
            if (dropCache) {
                PageCache.removeEntry(pageJson)
            }
        }
        if (pageLoader == null || dropCache) {
            pageLoader = PageLoader(this, pageJson, pageLoadingServer)
        }

        // Start the page loader (which may load if needed)
        pageLoader?.startLoading(this, CustomAppConfigManager.currentConfig().pageLoadingMode == AppConfigPageLoadingMode.HotReloadServer)
    }

    private fun stopPageLoad() {
        pageLoader?.stopLoading()
    }

    override fun onPageUpdated(page: Page) {
        var inflateLayout = (page.layout ?: emptyMap()).toMutableMap()
        if (Inflators.viewlet.findInflatableNameInAttributes(page.layout) != "frameContainer") {
            val wrappedLayout = (page.layout ?: emptyMap()).toMutableMap()
            if (wrappedLayout["width"] == null) {
                wrappedLayout["width"] = "stretchToParent"
            }
            if (wrappedLayout["height"] == null) {
                wrappedLayout["height"] = "stretchToParent"
            }
            inflateLayout = mutableMapOf(
                Pair("viewlet", "frameContainer"),
                Pair("recycling", true),
                Pair("items", listOf(wrappedLayout))
            )
        }
        ViewletUtil.assertInflateOn(activityView, inflateLayout)
        currentPageHash = page.hash
    }

    override fun onPageLoadingEvent(event: PageLoader.Event) {
        if (event == PageLoader.Event.LoadingFailed) {
            activityView.setBackgroundColor(Color.RED)
        }
    }

}
