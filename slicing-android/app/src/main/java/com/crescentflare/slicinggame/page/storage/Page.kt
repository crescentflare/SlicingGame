package com.crescentflare.slicinggame.page.storage

import com.crescentflare.jsoninflator.utility.InflatorMapUtil
import com.crescentflare.slicinggame.infrastructure.coreextensions.sha256
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken

/**
 * Page storage: a single page item
 */
class Page {

    // --
    // Members
    // --

    var originalData = emptyMap<String, Any>()
    val hash: String
    var creationTime: Long = 0
    private val mapUtil = InflatorMapUtil()


    // --
    // Initialization
    // --

    constructor(jsonString: String) {
        var resultHash = "unknown"
        val type = object : TypeToken<Map<String, Any>>() {
        }.type
        try {
            val result = Gson().fromJson<Map<String, Any>>(jsonString, type)
            if (result != null) {
                originalData = result
                resultHash = jsonString.sha256()
            }
        } catch (ignored: Exception) {
            // No implementation
        }
        hash = resultHash
        updateCreationTime()
    }

    constructor(map: Map<String, Any>, hash: String = "unknown") {
        originalData = map
        this.hash = hash
        updateCreationTime()
    }


    // --
    // State updates
    // --

    fun updateCreationTime() {
        creationTime = System.currentTimeMillis()
    }


    // --
    // Extract data
    // --

    val modules: List<Map<String, Any>>?
        get() {
            return optionalObjectMapList(originalData, "modules")
        }

    val layout: Map<String, Any>?
        get() {
            val dataSetMap = mapUtil.asStringObjectMap(originalData["dataSets"])
            if (dataSetMap != null) {
                val layout = mapUtil.asStringObjectMap(dataSetMap["layout"])
                if (layout != null) {
                    return layout
                }
            }
            return null
        }


    // --
    // Helper
    // --

    @Suppress("unchecked_cast")
    private fun optionalObjectMapList(map: Map<String, Any>, key: String): List<Map<String, Any>>? {
        val objectList = mapUtil.optionalObjectList(map, key)
        return if (objectList.size > 0 && mapUtil.asStringObjectMap(objectList[0]) == null) null else objectList as List<Map<String, Any>>
    }

}
