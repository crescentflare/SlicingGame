package com.crescentflare.slicinggame.page.storage

import android.content.Context
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.GlobalScope
import kotlinx.coroutines.launch
import java.io.IOException

/**
 * Page storage: handles loading of pages
 */
class PageLoader(private val context: Context, private val location: String) {

    // --
    // Statics
    // --

    companion object {

        private const val forceInternalSyncLoad = true

    }


    // --
    // Members
    // --

    private var loading = false


    // --
    // Loading
    // --

    fun load(completion: (page: Page?, exception: Throwable?) -> Unit) {
        val cachedPage = PageCache.getEntry(location)
        if (cachedPage != null) {
            completion(cachedPage, null)
        } else {
            loadInternal {
                if (it != null) {
                    PageCache.storeEntry(location, it)
                }
                completion(it, null)
            }
        }
    }

    private fun loadInternal(completion: (page: Page?) -> Unit) {
        if (forceInternalSyncLoad) {
            completion(loadInternalSync())
        } else {
            loading = true
            GlobalScope.launch(Dispatchers.Default) {
                val page = loadInternalSync()
                GlobalScope.launch(Dispatchers.Main) {
                    loading = false
                    completion(page)
                }
            }
        }
    }

    fun loadInternalSync(): Page? {
        try {
            val stream = context.assets.open("pages/$location")
            val jsonString = stream.bufferedReader().use { it.readText() }
            return Page(jsonString)
        } catch (ignored: IOException) {
        }
        return null
    }

}
