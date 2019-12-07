package com.crescentflare.slicinggame

import android.app.Application
import com.crescentflare.slicinggame.components.utility.ViewletUtil
import com.crescentflare.slicinggame.infrastructure.inflator.Inflators


/**
 * The main application singleton
 */
class BaseApplication : Application() {

    // --
    // Initialization
    // --

    override fun onCreate() {
        super.onCreate()
        registerViewlets()
    }


    // --
    // Inflatable registration
    // --

    private fun registerViewlets() {
        // Enable platform specific attributes
        Inflators.viewlet.setMergeSubAttributes(listOf("android"))
        Inflators.viewlet.setExcludeAttributes(listOf("ios"))

        // Simple viewlets
        Inflators.viewlet.register("view", ViewletUtil.basicViewViewlet)
    }

}
