package com.crescentflare.slicinggame.components.basicviews

import android.annotation.TargetApi
import android.content.Context
import android.os.Build
import android.util.AttributeSet
import com.crescentflare.jsoninflator.JsonInflatable
import com.crescentflare.jsoninflator.binder.InflatorBinder
import com.crescentflare.jsoninflator.utility.InflatorMapUtil
import com.crescentflare.slicinggame.components.utility.ImageSource
import com.crescentflare.slicinggame.components.utility.ViewletUtil
import com.crescentflare.unilayout.views.UniImageView


/**
 * Basic view: an image view
 */
open class ImageView : UniImageView {

    // --
    // Static: viewlet integration
    // --

    companion object {

        val viewlet: JsonInflatable = object : JsonInflatable {
            override fun create(context: Context): Any {
                return ImageView(context)
            }

            override fun update(mapUtil: InflatorMapUtil, obj: Any, attributes: Map<String, Any>, parent: Any?, binder: InflatorBinder?): Boolean {
                if (obj is ImageView) {
                    // Apply image
                    val stretchType = StretchType.fromString(mapUtil.optionalString(attributes, "stretchType", ""))
                    obj.scaleType = stretchType.toScaleType()
                    obj.source = ImageSource.fromValue(attributes["source"])

                    // Generic view properties
                    ViewletUtil.applyGenericViewAttributes(mapUtil, obj, attributes)
                    return true
                }
                return false
            }

            override fun canRecycle(mapUtil: InflatorMapUtil, obj: Any, attributes: Map<String, Any>): Boolean {
                return obj::class == ImageView::class
            }
        }
    }


    // --
    // Initialization
    // --

    @JvmOverloads
    constructor(
        context: Context,
        attrs: AttributeSet? = null,
        defStyleAttr: Int = 0)
            : super(context, attrs, defStyleAttr)

    @TargetApi(Build.VERSION_CODES.LOLLIPOP)
    constructor(
        context: Context,
        attrs: AttributeSet?,
        defStyleAttr: Int,
        defStyleRes: Int)
            : super(context, attrs, defStyleAttr, defStyleRes)

    init {
        // No implementation
    }


    // --
    // Configurable values
    // --

    var source: ImageSource? = null
        set(source) {
            field = source
            if (source != null) {
                source.getDrawable(context) {
                    if (field === source) {
                        setImageDrawable(it)
                    }
                }
            } else {
                setImageDrawable(null)
            }
        }


    // --
    // Scale type enum
    // --

    enum class StretchType(val value: String) {

        None("none"),
        Fill("fill"),
        AspectFit("aspectFit"),
        AspectCrop("aspectCrop");

        fun toScaleType(): ScaleType {
            return when(this) {
                Fill -> ScaleType.FIT_XY
                AspectFit -> ScaleType.FIT_CENTER
                AspectCrop -> ScaleType.CENTER_CROP
                else -> ScaleType.CENTER
            }
        }

        companion object {

            fun fromString(string: String?): StretchType {
                for (enum in values()) {
                    if (enum.value == string) {
                        return enum
                    }
                }
                return None
            }

        }

    }

}
