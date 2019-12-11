package com.crescentflare.slicinggame.components.utility

import android.content.Context
import android.graphics.drawable.Drawable
import androidx.core.content.ContextCompat
import com.bumptech.glide.Glide
import com.bumptech.glide.request.target.CustomTarget
import com.bumptech.glide.request.transition.Transition
import com.crescentflare.slicinggame.infrastructure.coreextensions.urlDecode
import com.crescentflare.slicinggame.infrastructure.coreextensions.urlEncode
import com.crescentflare.slicinggame.infrastructure.inflator.Inflators

/**
 * Component utility: defines the source of an image
 */
class ImageSource {

    // --
    // Static: factory method
    // --

    companion object {

        fun fromValue(value: Any?): ImageSource? {
            if (value is Map<*, *>) {
                val result: Map<String, Any>? = Inflators.viewlet.mapUtil.asStringObjectMap(value)
                if (result != null) {
                    return ImageSource(result)
                }
            } else {
                val tempMap = mapOf(Pair("value", value))
                Inflators.viewlet.mapUtil.optionalString(tempMap, "value", null)?.let {
                    return ImageSource(it)
                }
            }
            return null
        }

    }


    // --
    // Members
    // --

    var type = Type.Unknown
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
            type = Type.fromString(checkString.substring(0, schemeMarker))
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
        type = Type.fromString(mapUtil.optionalString(map, "type", null))
        mapUtil.optionalString(map, "name", null)?.let {
            name = it
        }
        parameters = map.filter { it.key != "type" && it.key != "name" }.toMutableMap()
    }

    constructor(context: Context, resourceId: Int) {
        type = Type.InternalImage
        name = context.resources.getResourceEntryName(resourceId)
    }


    // --
    // Conversion
    // --

    val uri: String
        get() {
            var uri = "${type.value}://$name"
            getParameterString()?.let {
                uri += "?$it"
            }
            return uri
        }

    val map: Map<String, Any>
        get() {
            val map = mutableMapOf<String, Any>(Pair("type", type.value), Pair("name", name))
            map.putAll(parameters)
            return map
        }


    // --
    // Obtain drawable
    // --

    fun getDrawable(context: Context, callback: (drawable: Drawable?) -> Unit) {
        if (type == Type.InternalImage) {
            val resourceId = context.resources.getIdentifier(name, "drawable", context.packageName)
            if (resourceId > 0) {
                return callback(ContextCompat.getDrawable(context, resourceId))
            } else {
                callback(null)
            }
        } else if (type == Type.Online || type == Type.SecureOnline) {
            Glide.with(context)
                .`as`(Drawable::class.java)
                .load(uri)
                .into(object : CustomTarget<Drawable>() {
                    override fun onLoadCleared(placeholder: Drawable?) {
                        // No implementation
                    }

                    override fun onLoadFailed(errorDrawable: Drawable?) {
                        callback(null)
                    }

                    override fun onResourceReady(resource: Drawable, transition: Transition<in Drawable>?) {
                        callback(resource)
                    }
                })
        } else {
            callback(null)
        }
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


    // --
    // Type enum
    // --

    enum class Type(val value: String) {

        Unknown("unknown"),
        InternalImage("app"),
        Online("http"),
        SecureOnline("https");

        companion object {

            fun fromString(string: String?): Type {
                for (enum in values()) {
                    if (enum.value == string) {
                        return enum
                    }
                }
                return Unknown
            }

        }

    }

}
