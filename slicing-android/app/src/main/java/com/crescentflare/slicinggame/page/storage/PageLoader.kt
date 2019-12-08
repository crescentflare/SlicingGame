package com.crescentflare.slicinggame.page.storage

import android.content.Context
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.GlobalScope
import kotlinx.coroutines.launch
import okhttp3.*
import java.io.IOException

/**
 * Page storage: handles loading of pages from several sources
 */
class PageLoader(private val context: Context, location: String, serverPrefix: String = "") {

    // --
    // Statics
    // --

    companion object {

        private const val forceInternalSyncLoad = true

    }


    // --
    // Members
    // --

    private val location: String = serverPrefix + location
    private val entry: String = location
    private val loadInternal: Boolean = !this.location.contains("://")
    private var loading = false


    // --
    // Loading
    // --

    fun load(completion: (page: Page?, exception: Throwable?) -> Unit) {
        val cachedPage = PageCache.getEntry(entry)
        if (cachedPage != null) {
            completion(cachedPage, null)
        } else if (loadInternal) {
            loadInternal {
                if (it != null) {
                    PageCache.storeEntry(entry, it)
                }
                completion(it, null)
            }
        } else {
            loadOnline { page, exception ->
                if (page != null) {
                    PageCache.storeEntry(entry, page)
                }
                completion(page, exception)
            }
        }
    }

    private fun loadOnline(completion: (page: Page?, exception: Throwable?) -> Unit) {
        if (!loadInternal) {
            val client = OkHttpClient()
            loading = true
            client.newCall(Request.Builder().url(location).build()).enqueue(object : Callback {
                override fun onFailure(call: Call, exception: IOException) {
                    GlobalScope.launch(Dispatchers.Main) {
                        loading = false
                        completion(null, exception)
                    }
                }

                @Throws(IOException::class)
                override fun onResponse(call: Call, response: Response) {
                    val jsonString = response.body()?.string()
                    if (jsonString != null) {
                        val page = Page(jsonString)
                        GlobalScope.launch(Dispatchers.Main) {
                            loading = false
                            completion(page, null)
                        }
                    } else {
                        GlobalScope.launch(Dispatchers.Main) {
                            loading = false
                            completion(null, null)
                        }
                    }
                }
            })
        } else {
            completion(null, null)
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
        if (loadInternal) {
            try {
                val stream = context.assets.open("pages/$location")
                val jsonString = stream.bufferedReader().use { it.readText() }
                return Page(jsonString)
            } catch (ignored: IOException) {
            }
        }
        return null
    }

}
