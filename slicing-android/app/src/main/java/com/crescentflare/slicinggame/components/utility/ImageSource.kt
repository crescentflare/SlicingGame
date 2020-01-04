package com.crescentflare.slicinggame.components.utility

import android.content.Context
import android.content.res.Resources
import android.graphics.Bitmap
import android.graphics.drawable.Drawable
import androidx.core.content.ContextCompat
import com.bumptech.glide.Glide
import com.bumptech.glide.load.engine.bitmap_recycle.BitmapPool
import com.bumptech.glide.load.resource.bitmap.BitmapTransformation
import com.bumptech.glide.request.target.CustomTarget
import com.bumptech.glide.request.transition.Transition
import com.bumptech.glide.util.Util
import com.crescentflare.slicinggame.infrastructure.coreextensions.urlDecode
import com.crescentflare.slicinggame.infrastructure.coreextensions.urlEncode
import com.crescentflare.slicinggame.infrastructure.inflator.Inflators
import java.security.MessageDigest


/**
 * Component utility: defines the source of an image
 */
class ImageSource: Comparable<ImageSource> {

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
    // Extract values
    // --

    private val density: Float?
        get() {
            if (parameters.containsKey("density")) {
                return Inflators.viewlet.mapUtil.optionalFloat(parameters, "density", 1f)
            }
            return null
        }

    private val forceWidth: Int?
        get() {
            val width = Inflators.viewlet.mapUtil.optionalDimension(parameters, "forceWidth", 0)
            if (width > 0) {
                return width
            }
            return null
        }

    private val forceHeight: Int?
        get() {
            val height = Inflators.viewlet.mapUtil.optionalDimension(parameters, "forceHeight", 0)
            if (height > 0) {
                return height
            }
            return null
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
                .transform(BitmapScaler(forceWidth, forceHeight, density))
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
    // Comparable implementation
    // --

    override fun compareTo(other: ImageSource): Int {
        return uri.compareTo(other.uri)
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


    // --
    // Image transformer class
    // --

    private class BitmapScaler(val forceWidth: Int? = null, val forceHeight: Int? = null, val density: Float? = null) : BitmapTransformation() {

        private val objectName = "ImageSource.BitmapScaler"

        override fun transform(pool: BitmapPool, toTransform: Bitmap, outWidth: Int, outHeight: Int): Bitmap {
            var newWidth = toTransform.width
            var newHeight = toTransform.height
            if (forceWidth != null) {
                newWidth = forceWidth
                newHeight = forceHeight ?: toTransform.height * newWidth / toTransform.width
            } else if (forceHeight != null) {
                newHeight = forceHeight
                newWidth = toTransform.width * newHeight / toTransform.height
            } else if (density != null && density != 0f) {
                newWidth = (toTransform.width.toFloat() * Resources.getSystem().displayMetrics.density / density).toInt()
                newHeight = (toTransform.height.toFloat() * Resources.getSystem().displayMetrics.density / density).toInt()
            }
            if (newWidth > 0 && newHeight > 0 && (newWidth != toTransform.width || newHeight != toTransform.height)) {
                return Bitmap.createScaledBitmap(toTransform, newWidth, newHeight, true)
            }
            return toTransform
        }

        override fun updateDiskCacheKey(messageDigest: MessageDigest) {
            messageDigest.update(objectName.toByteArray())
            if (forceWidth != null) {
                messageDigest.update(forceWidth.toString().toByteArray())
            }
            if (forceHeight != null) {
                messageDigest.update(forceHeight.toString().toByteArray())
            }
            if (density != null) {
                messageDigest.update(density.toString().toByteArray())
            }
        }

        override fun equals(other: Any?): Boolean {
            if (other is BitmapScaler) {
                return other.forceWidth == forceWidth && other.forceHeight == forceHeight && other.density == density
            }
            return false
        }

        override fun hashCode(): Int {
            val hashCodes = listOf(
                Util.hashCode(forceWidth ?: 0),
                Util.hashCode(forceHeight ?: 0),
                Util.hashCode(density ?: 0f)
            )
            var result = objectName.hashCode()
            for (hashCode in hashCodes) {
                result = Util.hashCode(result, hashCode)
            }
            return result
        }

    }

}
