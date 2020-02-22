package com.crescentflare.slicinggame.components.basicviews

import android.annotation.TargetApi
import android.content.Context
import android.os.Build
import android.util.AttributeSet
import android.util.TypedValue
import android.view.Gravity
import androidx.core.content.ContextCompat
import com.crescentflare.jsoninflator.JsonInflatable
import com.crescentflare.jsoninflator.binder.InflatorBinder
import com.crescentflare.jsoninflator.utility.InflatorMapUtil
import com.crescentflare.slicinggame.R
import com.crescentflare.slicinggame.components.styling.AppFonts
import com.crescentflare.slicinggame.components.utility.ViewletUtil
import com.crescentflare.slicinggame.infrastructure.coreextensions.localized
import com.crescentflare.unilayout.views.UniTextView


/**
 * Basic view: a text view
 */
open class TextView : UniTextView {

    // --
    // Static: viewlet integration
    // --

    companion object {

        val viewlet: JsonInflatable = object : JsonInflatable {
            override fun create(context: Context): Any {
                return TextView(context)
            }

            override fun update(mapUtil: InflatorMapUtil, obj: Any, attributes: Map<String, Any>, parent: Any?, binder: InflatorBinder?): Boolean {
                if (obj is TextView) {
                    // Apply text styling
                    val defaultTextSize = obj.resources.getDimensionPixelSize(R.dimen.text)
                    val maxLines = mapUtil.optionalInteger(attributes, "maxLines", 0)
                    obj.typeface = AppFonts.getTypeface(mapUtil.optionalString(attributes, "font", "normal"))
                    obj.setTextSize(TypedValue.COMPLEX_UNIT_PX, mapUtil.optionalDimension(attributes, "textSize", defaultTextSize).toFloat())
                    obj.maxLines = if (maxLines == 0) Integer.MAX_VALUE else maxLines
                    obj.setTextColor(mapUtil.optionalColor(attributes,"textColor", ContextCompat.getColor(obj.context, R.color.text)))

                    // Apply text alignment
                    val textAlignment = TextAlignment.fromString(mapUtil.optionalString(attributes, "textAlignment", ""))
                    obj.gravity = textAlignment.toGravity()

                    // Text
                    obj.text = mapUtil.optionalString(attributes, "localizedText", null)?.localized(obj.context) ?: mapUtil.optionalString(attributes, "text", null)

                    // Generic view properties
                    ViewletUtil.applyGenericViewAttributes(mapUtil, obj, attributes)
                    return true
                }
                return false
            }

            override fun canRecycle(mapUtil: InflatorMapUtil, obj: Any, attributes: Map<String, Any>): Boolean {
                return obj::class == TextView::class
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
        typeface = AppFonts.getTypeface("normal")
        setTextSize(TypedValue.COMPLEX_UNIT_PX, context.resources.getDimensionPixelSize(R.dimen.text).toFloat())
        setTextColor(ContextCompat.getColor(context, R.color.text))
    }


    // --
    // Text alignment enum
    // --

    enum class TextAlignment(val value: String) {

        Left("left"),
        Center("center"),
        Right("right");

        fun toGravity(): Int {
            return when(this) {
                Center -> Gravity.CENTER
                Right -> Gravity.RIGHT
                else -> Gravity.LEFT
            }
        }

        companion object {

            fun fromString(string: String?): TextAlignment {
                for (enum in values()) {
                    if (enum.value == string) {
                        return enum
                    }
                }
                return Left
            }

        }

    }

}
