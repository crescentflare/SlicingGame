package com.crescentflare.slicinggame.infrastructure.events

import com.crescentflare.slicinggame.infrastructure.coreextensions.urlDecode
import com.crescentflare.slicinggame.infrastructure.coreextensions.urlEncode
import com.crescentflare.slicinggame.infrastructure.inflator.Inflators


/**
 * Event system: defines an event with optional parameters
 */
class AppEvent {

    // --
    // Static: factory method
    // --

    companion object {

        fun fromValue(value: Any?): AppEvent? {
            if (value is Map<*, *>) {
                val result: Map<String, Any>? = Inflators.viewlet.mapUtil.asStringObjectMap(value)
                if (result != null) {
                    return AppEvent(result)
                }
            } else {
                val tempMap = mapOf(Pair("value", value))
                Inflators.viewlet.mapUtil.optionalString(tempMap, "value", null)?.let {
                    return AppEvent(it)
                }
            }
            return null
        }

    }


    // --
    // Members
    // --

    var type = ""
    var parameters = mutableMapOf<String, Any>()
    var name = ""


    // --
    // Initialization
    // --

    constructor(string: String) {
        // Extract type from scheme
        var checkString = string
        val schemeMarker = checkString.indexOf("://")
        if (schemeMarker >= 0) {
            type = checkString.substring(0, schemeMarker)
            checkString = checkString.substring(schemeMarker + 3)
        }

        // Extract parameters
        val parameterMarker = checkString.indexOf('?')
        if (parameterMarker >= 0) {
            // Get parameter string
            val parameterString = checkString.substring(parameterMarker + 1)
            checkString = checkString.substring(0, parameterMarker)

            // Split into separate parameters and fill dictionary
            val parameterItems = parameterString.split("&")
            for (parameterItem in parameterItems) {
                val parameterSet = parameterItem.split("=")
                if (parameterSet.size == 2) {
                    val key = parameterSet[0].urlDecode()
                    parameters[key] = parameterSet[1].urlDecode()
                }
            }
        }

        // Finally set name to the remaining string
        name = checkString
    }

    constructor(map: Map<String, Any>) {
        val mapUtil = Inflators.viewlet.mapUtil
        type = mapUtil.optionalString(map, "type", null) ?: "unknown"
        mapUtil.optionalString(map, "name", null)?.let {
            name = it
        }
        parameters = map.filter { it.key != "type" && it.key != "name" }.toMutableMap()
    }


    // --
    // Conversion
    // --

    val uri: String
        get() {
            var uri = "$type://$name"
            getParameterString()?.let {
                uri += "?$it"
            }
            return uri
        }

    val map: Map<String, Any>
        get() {
            val map = mutableMapOf<String, Any>(Pair("type", type), Pair("name", name))
            map.putAll(parameters)
            return map
        }


    // --
    // Helper
    // --

    private fun getParameterString(ignoreParams: List<String> = emptyList()): String? {
        if (parameters.isNotEmpty()) {
            var parameterString = ""
            for (key in parameters.keys.sorted()) {
                var ignore = false
                for (ignoreParam in ignoreParams) {
                    if (key == ignoreParam) {
                        ignore = true
                        break
                    }
                }
                val stringValue = Inflators.viewlet.mapUtil.optionalString(parameters, key, null)
                if (!ignore && stringValue != null) {
                    if (parameterString.isNotEmpty()) {
                        parameterString += "&"
                    }
                    parameterString += key.urlEncode() + "=" + stringValue.urlEncode()
                }
            }
            if (parameterString.isNotEmpty()) {
                return parameterString
            }
        }
        return null
    }

}
