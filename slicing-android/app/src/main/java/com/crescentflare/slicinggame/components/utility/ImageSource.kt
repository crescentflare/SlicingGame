package com.crescentflare.slicinggame.components.utility

import android.content.Context
import android.graphics.drawable.Drawable
import androidx.core.content.ContextCompat
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

        // Set name to the remaining string
        name = checkString
    }

    constructor(map: Map<String, Any>) {
        val mapUtil = Inflators.viewlet.mapUtil
        type = Type.fromString(mapUtil.optionalString(map, "type", null))
        mapUtil.optionalString(map, "name", null)?.let {
            name = it
        }
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
            return "${type.value}://$name"
        }

    val map: Map<String, Any>
        get() {
            return mapOf<String, Any>(Pair("type", type.value), Pair("name", name))
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
        } else {
            callback(null)
        }
    }


    // --
    // Type enum
    // --

    enum class Type(val value: String) {

        Unknown("unknown"),
        InternalImage("app");

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
