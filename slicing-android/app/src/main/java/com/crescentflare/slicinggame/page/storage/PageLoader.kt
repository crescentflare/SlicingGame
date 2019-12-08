package com.crescentflare.slicinggame.page.storage

import android.content.Context
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.GlobalScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import okhttp3.*
import java.io.IOException
import java.lang.ref.WeakReference
import java.util.concurrent.TimeUnit

/**
 * Page storage: handles loading of pages from several sources
 */
class PageLoader(private val context: Context, location: String, serverPrefix: String = "") {

    // --
    // Statics
    // --

    companion object {

        private const val cacheMinute = 1000 * 60
        private const val forceInternalSyncLoad = true
        private const val cacheTimeout = cacheMinute * 5

    }


    // --
    // Members
    // --

    private var listener: WeakReference<PageLoaderListener>? = null
    private val location: String = serverPrefix + location
    private val entry: String = location
    private val loadInternal: Boolean = !this.location.contains("://")
    private var loading = false
    private var waiting = false
    private var continuousLoad = false


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
            loadOnline("ignore") { page, exception ->
                if (page != null) {
                    PageCache.storeEntry(entry, page)
                }
                completion(page, exception)
            }
        }
    }

    private fun loadOnline(currentHash: String, completion: (page: Page?, exception: Throwable?) -> Unit) {
        if (!loadInternal) {
            val client = OkHttpClient.Builder().readTimeout(20, TimeUnit.SECONDS).build()
            loading = true
            client.newCall(Request.Builder().url(location).header("X-Mock-Wait-Change-Hash", currentHash).build()).enqueue(object : Callback {
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


    // --
    // Advanced loading with cache and hot reload integration
    // --

    fun startLoading(listener: PageLoaderListener, hotReload: Boolean, ignoreCache: Boolean = false) {
        var cacheStable = false
        this.listener = WeakReference(listener)
        continuousLoad = hotReload
        if (!ignoreCache) {
            val page = PageCache.getEntry(entry)
            if (page != null) {
                val expired = System.currentTimeMillis() - page.creationTime >= cacheTimeout
                cacheStable = loadInternal || (!hotReload && !expired)
            }
        }
        if (!cacheStable) {
            tryNextLoad()
        } else {
            this.listener?.get()?.onPageLoadingEvent(Event.LoadingCached)
        }
    }

    fun stopLoading() {
        listener = null
    }

    private fun tryNextLoad() {
        if (!loading && !waiting && listener != null) {
            listener?.get()?.onPageLoadingEvent(Event.LoadingStarted)
            if (loadInternal) {
                loadInternal {
                    if (it != null) {
                        listener?.get()?.onPageLoadingEvent(Event.LoadingFinished)
                        if (PageCache.hasEntry(entry)) {
                            listener?.get()?.onPageLoadingEvent(Event.ChangedPageData)
                        } else {
                            listener?.get()?.onPageLoadingEvent(Event.ReceivedNewPageData)
                        }
                        PageCache.storeEntry(entry, it)
                        listener?.get()?.onPageUpdated(it)
                    } else {
                        listener?.get()?.onPageLoadingEvent(Event.LoadingFailed)
                    }
                }
            } else {
                val hash = PageCache.getEntry(entry)?.hash ?: "unknown"
                loadOnline(if (continuousLoad) hash else "ignored") { page, exception ->
                    var waitingTime = 2000
                    if (exception != null) {
                        listener?.get()?.onPageLoadingEvent(Event.LoadingFailed)
                    } else {
                        listener?.get()?.onPageLoadingEvent(Event.LoadingFinished)
                        waitingTime = 100
                    }
                    if (page != null) {
                        if (hash != page.hash) {
                            if (PageCache.hasEntry(entry)) {
                                listener?.get()?.onPageLoadingEvent(Event.ChangedPageData)
                            } else {
                                listener?.get()?.onPageLoadingEvent(Event.ReceivedNewPageData)
                            }
                            PageCache.storeEntry(entry, page)
                            listener?.get()?.onPageUpdated(page)
                        } else {
                            listener?.get()?.onPageLoadingEvent(Event.IgnoredSamePageData)
                            PageCache.getEntry(entry)?.updateCreationTime()
                        }
                    } else if (exception == null) {
                        listener?.get()?.onPageLoadingEvent(Event.IgnoredSamePageData)
                    }
                    if (continuousLoad) {
                        waiting = true
                        GlobalScope.launch(Dispatchers.Main) {
                            delay(waitingTime.toLong())
                            waiting = false
                            tryNextLoad()
                        }
                    }
                }
            }
        } else {
            listener?.get()?.onPageLoadingEvent(Event.LoadingMerged)
        }
    }


    // --
    // Event enum
    // --

    enum class Event {

        LoadingStarted,
        LoadingFinished,
        LoadingFailed,
        LoadingMerged,
        LoadingCached,
        ReceivedNewPageData,
        ChangedPageData,
        IgnoredSamePageData

    }

}
