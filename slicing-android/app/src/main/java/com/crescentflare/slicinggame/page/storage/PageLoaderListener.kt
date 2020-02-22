package com.crescentflare.slicinggame.page.storage

/**
 * Page storage: an interface to listen for page loading updates
 */
interface PageLoaderListener {

    fun onPageUpdated(page: Page)
    fun onPageLoadingEvent(event: PageLoader.Event)

}
