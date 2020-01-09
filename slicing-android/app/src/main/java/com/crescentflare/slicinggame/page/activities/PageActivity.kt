package com.crescentflare.slicinggame.page.activities

import android.content.Context
import android.content.Intent
import android.content.res.Resources
import android.graphics.Color
import android.graphics.drawable.ColorDrawable
import android.os.Build
import android.os.Bundle
import android.view.View
import android.view.ViewGroup
import android.view.ViewParent
import android.view.WindowManager
import androidx.appcompat.app.AppCompatActivity
import com.crescentflare.slicinggame.components.containers.PageContainerView
import com.crescentflare.slicinggame.components.types.NavigationBarComponent
import com.crescentflare.slicinggame.components.utility.ViewletUtil
import com.crescentflare.slicinggame.infrastructure.appconfig.AppConfigPageLoadingMode
import com.crescentflare.slicinggame.infrastructure.appconfig.CustomAppConfigManager
import com.crescentflare.slicinggame.infrastructure.coreextensions.colorIntensity
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

    private val activityView by lazy { PageContainerView(this) }
    private var statusBarColor = Color.BLACK
    private var navigationBarColor = Color.BLACK
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
        activityView.setBackgroundColor(Color.WHITE)
        setContentView(activityView)

        // Set up properties to allow transparency in the status and navigation bars
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            // Set flags to allow control over the colors, fetch defaults
            window.setFlags(WindowManager.LayoutParams.FLAG_DRAWS_SYSTEM_BAR_BACKGROUNDS, WindowManager.LayoutParams.FLAG_DRAWS_SYSTEM_BAR_BACKGROUNDS)
            statusBarColor = window.statusBarColor
            navigationBarColor = window.navigationBarColor

            // Disable clipping in the window view stack, allow some views to draw under the system bars
            var recursiveView: ViewParent? = activityView
            while (recursiveView is ViewGroup) {
                recursiveView.clipChildren = false
                recursiveView.clipToPadding = false
                recursiveView = recursiveView.parent
            }
        }
        updateSystemBars()

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
    // System bar color and transparency customization
    // --

    private fun updateSystemBars() {
        val titleBarColor = (activityView.titleBarView as? NavigationBarComponent)?.averageColor ?: viewBackgroundColor(activityView.titleBarView)
        val checkStatusBarColor = titleBarColor ?: viewBackgroundColor(activityView) ?: 0
        val lightStatusContent = checkStatusBarColor.colorIntensity() < 0.25
        updateStatusBarColor(checkStatusBarColor and 0xffffff, lightStatusContent)
        updateNavigationBarColor(0x00ffffff, false)
    }

    private fun updateStatusBarColor(color: Int, lightContent: Boolean) {
        if (statusBarColor == color) {
            return
        }
        statusBarColor = color
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val decor = window.decorView
            window.statusBarColor = statusBarColor
            if (!lightContent) {
                decor.systemUiVisibility = decor.systemUiVisibility or View.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR
            } else {
                decor.systemUiVisibility -= decor.systemUiVisibility and View.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR
            }
        }
    }

    private fun updateNavigationBarColor(color: Int, lightContent: Boolean) {
        if (navigationBarColor == color) {
            return
        }
        navigationBarColor = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O || lightContent) color else 0xff000000.toInt()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            var setColor = navigationBarColor
            val displayMetrics = Resources.getSystem().displayMetrics
            val disableTransparency = displayMetrics.widthPixels > displayMetrics.heightPixels
            if (disableTransparency) {
                val baseColor = setColor and 0xffffff
                setColor = (0xff000000 or baseColor.toLong()).toInt()
            }
            window.navigationBarColor = setColor
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val decor = window.decorView
                if (!lightContent) {
                    decor.systemUiVisibility = decor.systemUiVisibility or View.SYSTEM_UI_FLAG_LIGHT_NAVIGATION_BAR
                } else {
                    decor.systemUiVisibility -= decor.systemUiVisibility and View.SYSTEM_UI_FLAG_LIGHT_NAVIGATION_BAR
                }
            }
        }
    }

    private fun viewBackgroundColor(view: View?): Int? {
        (view?.background as? ColorDrawable)?.let {
            return it.color
        }
        return null
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
        if (Inflators.viewlet.findInflatableNameInAttributes(page.layout) != "pageContainer") {
            val wrappedLayout = (page.layout ?: emptyMap()).toMutableMap()
            if (wrappedLayout["width"] == null) {
                wrappedLayout["width"] = "stretchToParent"
            }
            if (wrappedLayout["height"] == null) {
                wrappedLayout["height"] = "stretchToParent"
            }
            inflateLayout = mutableMapOf(
                Pair("viewlet", "pageContainer"),
                Pair("backgroundColor", "#fff"),
                Pair("recycling", true),
                Pair("contentItems", listOf(wrappedLayout))
            )
        }
        ViewletUtil.assertInflateOn(activityView, inflateLayout)
        currentPageHash = page.hash
        updateSystemBars()
    }

    override fun onPageLoadingEvent(event: PageLoader.Event) {
        if (event == PageLoader.Event.LoadingFailed) {
            activityView.setBackgroundColor(Color.RED)
        }
    }

}
