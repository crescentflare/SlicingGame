package com.crescentflare.slicinggame.page.storage

/**
 * Page storage: cached loaded page items
 */
object PageCache {

    // --
    // Members
    // --

    private var entries = mutableMapOf<String, Page>()


    // --
    // Cache access
    // --

    fun hasEntry(cacheKey: String): Boolean {
        return entries[cacheKey] != null
    }

    fun getEntry(cacheKey: String): Page? {
        return entries[cacheKey]
    }

    fun storeEntry(cacheKey: String, page: Page) {
        entries[cacheKey] = page
    }

    fun removeEntry(cacheKey: String) {
        entries.remove(cacheKey)
    }

    fun clear() {
        entries = mutableMapOf()
    }

}
