package com.crescentflare.slicinggame

import android.app.Application
import com.crescentflare.dynamicappconfig.manager.AppConfigStorage
import com.crescentflare.jsoninflator.utility.InflatorResourceColorLookup
import com.crescentflare.jsoninflator.utility.InflatorResourceDimensionLookup
import com.crescentflare.slicinggame.components.basicviews.ImageView
import com.crescentflare.slicinggame.components.basicviews.TextView
import com.crescentflare.slicinggame.components.containers.FrameContainerView
import com.crescentflare.slicinggame.components.containers.GameContainerView
import com.crescentflare.slicinggame.components.containers.LinearContainerView
import com.crescentflare.slicinggame.components.containers.PageContainerView
import com.crescentflare.slicinggame.components.game.LevelCanvasView
import com.crescentflare.slicinggame.components.game.LevelSlicePreviewView
import com.crescentflare.slicinggame.components.game.LevelView
import com.crescentflare.slicinggame.components.navigationbars.GameTitleBarView
import com.crescentflare.slicinggame.components.navigationbars.SimpleBottomBarView
import com.crescentflare.slicinggame.components.styling.AppFonts
import com.crescentflare.slicinggame.components.utility.ViewletUtil
import com.crescentflare.slicinggame.infrastructure.appconfig.CustomAppConfigManager
import com.crescentflare.slicinggame.infrastructure.inflator.Inflators


/**
 * The main application singleton
 */
class BaseApplication : Application(), AppConfigStorage.ChangedConfigListener {

    // --
    // Initialization
    // --

    override fun onCreate() {
        // Enable app config utility for non-release builds
        super.onCreate()
        if (BuildConfig.BUILD_TYPE != "release") {
            AppConfigStorage.instance.init(this, CustomAppConfigManager.instance)
            AppConfigStorage.instance.addChangedConfigListener(this)
            onChangedConfig()
        }

        // Configure framework
        AppFonts.setContext(this)
        registerViewlets()
    }


    // --
    // App config integration
    // --

    override fun onChangedConfig() {
        // No implementation needed (for now)
    }


    // --
    // Inflatable registration
    // --

    private fun registerViewlets() {
        // Enable platform specific attributes
        Inflators.viewlet.setMergeSubAttributes(listOf("android"))
        Inflators.viewlet.setExcludeAttributes(listOf("ios"))

        // Lookups
        Inflators.viewlet.setColorLookup(InflatorResourceColorLookup(this))
        Inflators.viewlet.setDimensionLookup(InflatorResourceDimensionLookup(this))

        // Basic views
        Inflators.viewlet.register("image", ImageView.viewlet)
        Inflators.viewlet.register("text", TextView.viewlet)
        Inflators.viewlet.register("view", ViewletUtil.basicViewViewlet)

        // Containers
        Inflators.viewlet.register("frameContainer", FrameContainerView.viewlet)
        Inflators.viewlet.register("gameContainer", GameContainerView.viewlet)
        Inflators.viewlet.register("linearContainer", LinearContainerView.viewlet)
        Inflators.viewlet.register("pageContainer", PageContainerView.viewlet)

        // Game
        Inflators.viewlet.register("level", LevelView.viewlet)
        Inflators.viewlet.register("levelCanvas", LevelCanvasView.viewlet)
        Inflators.viewlet.register("levelSlicePreview", LevelSlicePreviewView.viewlet)

        // Navigation bars
        Inflators.viewlet.register("gameTitleBar", GameTitleBarView.viewlet)
        Inflators.viewlet.register("simpleBottomBar", SimpleBottomBarView.viewlet)
    }

}
