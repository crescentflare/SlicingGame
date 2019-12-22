package com.crescentflare.slicinggame.page.modules

import com.crescentflare.slicinggame.infrastructure.events.AppEvent
import com.crescentflare.slicinggame.page.activities.PageActivity

/**
 * Page module: provides an interface for separating controller logic into modules
 */
interface PageModule {

    val handleEventTypes: List<String>

    fun onCreate(activity: PageActivity)
    fun onResume()
    fun onPause()
    fun onDestroy()
    fun onLowMemory()
    fun onBackPressed(): Boolean

    fun handleEvent(event: AppEvent, sender: Any?): Boolean

}
