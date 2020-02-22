package com.crescentflare.slicinggame.components.utility

import android.content.Context
import android.view.View
import android.view.ViewGroup
import com.crescentflare.jsoninflator.JsonInflatable
import com.crescentflare.jsoninflator.binder.InflatableRef
import com.crescentflare.jsoninflator.binder.InflatorAnnotationBinder
import com.crescentflare.jsoninflator.binder.InflatorBinder
import com.crescentflare.jsoninflator.utility.InflatorMapUtil
import com.crescentflare.jsoninflator.utility.InflatorNestedResult
import com.crescentflare.slicinggame.BuildConfig
import com.crescentflare.slicinggame.infrastructure.inflator.Inflators
import com.crescentflare.unilayout.helpers.UniLayoutParams
import com.crescentflare.unilayout.views.UniView
import org.junit.Assert

/**
 * Component utility: shared utilities for viewlet integration, also contains the viewlet for a basic view
 */
object ViewletUtil {

    // --
    // Basic view viewlet
    // --

    val basicViewViewlet: JsonInflatable = object : JsonInflatable {

        override fun create(context: Context): Any {
            return UniView(context)
        }

        override fun update(mapUtil: InflatorMapUtil, obj: Any, attributes: Map<String, Any>, parent: Any?, binder: InflatorBinder?): Boolean {
            if (obj is UniView) {
                applyGenericViewAttributes(mapUtil, obj, attributes)
            }
            return true
        }

        override fun canRecycle(mapUtil: InflatorMapUtil, obj: Any, attributes: Map<String, Any>): Boolean {
            return obj::class == UniView::class
        }

    }


    // --
    // Inflate with assertion
    // --

    fun assertInflateOn(view: View, attributes: Map<String, Any>?, binder: InflatorBinder? = null) {
        assertInflateOn(view, attributes, null, binder)
    }

    fun assertInflateOn(view: View, attributes: Map<String, Any>?, parent: ViewGroup?, binder: InflatorBinder? = null) {
        val inflateResult = Inflators.viewlet.inflateOn(view, attributes, parent, binder)
        if (BuildConfig.DEBUG) {
            // First check if attributes are not null
            Assert.assertNotNull("Attributes are null, load issue?", attributes)

            // Check viewlet name
            val viewletName = Inflators.viewlet.findInflatableNameInAttributes(attributes)
            Assert.assertNotNull("No viewlet found, JSON structure issue?", viewletName)

            // Check if the viewlet is registered
            Assert.assertNotNull("No viewlet implementation found, registration issue of $viewletName?", Inflators.viewlet.findInflatableInAttributes(attributes))

            // Check result of inflate
            Assert.assertTrue("Can't inflate viewlet, class doesn't match with $viewletName?", inflateResult)

            // Check if there are any referenced views that are null
            if (binder is InflatorAnnotationBinder) {
                checkInflatableRefs(view)
            }
        }
    }

    private fun checkInflatableRefs(view: View) {
        for (field in view.javaClass.declaredFields) {
            for (annotation in field.declaredAnnotations) {
                if (annotation is InflatableRef) {
                    var isNull = true
                    try {
                        field.isAccessible = true
                        if (field.get(view) != null) {
                            isNull = false
                        }
                    } catch (ignored: IllegalAccessException) {
                    }
                    Assert.assertFalse("Referenced view is null: " + annotation.value, isNull)
                }
            }
        }
    }


    // --
    // Child view creation
    // --

    fun createChildViewItem(mapUtil: InflatorMapUtil, currentItem: Any?, parent: ViewGroup, attributes: Map<String, Any>?, childViewItem: Any?, binder: InflatorBinder?): InflatorNestedResult {
        val recycling = mapUtil.optionalBoolean(attributes, "recycling", false)
        val result = Inflators.viewlet.inflateNestedItem(parent.context, currentItem, childViewItem, recycling, parent, binder)
        val view = result.items.firstOrNull()
        if (view is View) {
            val viewAttributes = result.getAttributes(0)
            applyLayoutAttributes(mapUtil, view, viewAttributes)
            val refId = mapUtil.optionalString(viewAttributes, "refId", null)
            if (refId != null) {
                binder?.onBind(refId, view)
            }
        }
        return result
    }

    fun createChildViews(mapUtil: InflatorMapUtil, container: ViewGroup, parent: ViewGroup, attributes: Map<String, Any>?, childViewItems: Any?, binder: InflatorBinder?) {
        // Inflate with optional recycling
        val currentItems = mutableListOf<Any>()
        for (index in 0 until container.childCount) {
            currentItems.add(container.getChildAt(index))
        }
        val recycling = mapUtil.optionalBoolean(attributes, "recycling", false)
        val result = Inflators.viewlet.inflateNestedItemList(container.context, currentItems, childViewItems, recycling, parent, binder)

        // First remove items that could not be recycled
        for (removeView in result.removedItems) {
            if (removeView is View) {
                container.removeView(removeView)
            }
        }

        // Process items (non-recycled items are added)
        for (index in result.items.indices) {
            val view = result.items[index]
            if (view is View) {
                // Set to container
                if (!result.isRecycled(index)) {
                    container.addView(view, index)
                }
                applyLayoutAttributes(mapUtil, view, result.getAttributes(index))

                // Bind reference
                val refId = mapUtil.optionalString(result.getAttributes(index), "refId", null)
                if (refId != null) {
                    binder?.onBind(refId, view)
                }
            }
        }
    }


    // --
    // Shared generic view handling
    // --

    fun applyGenericViewAttributes(mapUtil: InflatorMapUtil, view: View, attributes: Map<String, Any>) {
        // Visibility and color
        val visibility = mapUtil.optionalString(attributes, "visibility", "")
        view.visibility = when(visibility) {
            "hidden" -> View.GONE
            "invisible" -> View.INVISIBLE
            else -> View.VISIBLE
        }
        view.setBackgroundColor(mapUtil.optionalColor(attributes, "backgroundColor", 0))

        // Padding
        var defaultPadding = listOf(0, 0, 0, 0)
        val paddingArray = mapUtil.optionalDimensionList(attributes, "padding")
        if (paddingArray.size == 4) {
            defaultPadding = paddingArray
        }
        view.setPadding(
            mapUtil.optionalDimension(attributes, "paddingLeft", defaultPadding[0]),
            mapUtil.optionalDimension(attributes, "paddingTop", defaultPadding[1]),
            mapUtil.optionalDimension(attributes, "paddingRight", defaultPadding[2]),
            mapUtil.optionalDimension(attributes, "paddingBottom", defaultPadding[3])
        )

        // Capture touch
        view.isClickable = mapUtil.optionalBoolean(attributes, "blockTouch", false)
    }


    // --
    // Shared layout parameters handling
    // --

    fun applyLayoutAttributes(mapUtil: InflatorMapUtil, view: View, attributes: Map<String, Any>) {
        // Margin
        val layoutParams = if (view.layoutParams is UniLayoutParams) {
            view.layoutParams as UniLayoutParams
        } else {
            UniLayoutParams(ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT)
        }
        var defaultMargin = listOf(0, 0, 0, 0)
        val marginArray = mapUtil.optionalDimensionList(attributes, "margin")
        if (marginArray.size == 4) {
            defaultMargin = marginArray
        }
        layoutParams.leftMargin = mapUtil.optionalDimension(attributes, "marginLeft", defaultMargin[0])
        layoutParams.topMargin = mapUtil.optionalDimension(attributes, "marginTop", defaultMargin[1])
        layoutParams.rightMargin = mapUtil.optionalDimension(attributes, "marginRight", defaultMargin[2])
        layoutParams.bottomMargin = mapUtil.optionalDimension(attributes, "marginBottom", defaultMargin[3])
        layoutParams.spacingMargin = mapUtil.optionalDimension(attributes, "marginSpacing", 0)

        // Forced size or stretching
        val widthString = mapUtil.optionalString(attributes, "width", "")
        val heightString = mapUtil.optionalString(attributes, "height", "")
        layoutParams.width = when(widthString) {
            "stretchToParent" -> ViewGroup.LayoutParams.MATCH_PARENT
            "fitContent" -> ViewGroup.LayoutParams.WRAP_CONTENT
            else -> mapUtil.optionalDimension(attributes, "width", ViewGroup.LayoutParams.WRAP_CONTENT)
        }
        layoutParams.height = when(heightString) {
            "stretchToParent" -> ViewGroup.LayoutParams.MATCH_PARENT
            "fitContent" -> ViewGroup.LayoutParams.WRAP_CONTENT
            else -> mapUtil.optionalDimension(attributes, "height", ViewGroup.LayoutParams.WRAP_CONTENT)
        }

        // Size limits and weight
        layoutParams.minWidth = mapUtil.optionalDimension(attributes, "minWidth", 0)
        layoutParams.maxWidth = mapUtil.optionalDimension(attributes, "maxWidth", 0xFFFFFF)
        layoutParams.minHeight = mapUtil.optionalDimension(attributes, "minHeight", 0)
        layoutParams.maxHeight = mapUtil.optionalDimension(attributes, "maxHeight", 0xFFFFFF)
        layoutParams.weight = mapUtil.optionalFloat(attributes, "weight", 0f)

        // Gravity
        layoutParams.horizontalGravity = optionalHorizontalGravity(mapUtil, attributes, 0.0f)
        layoutParams.verticalGravity = optionalVerticalGravity(mapUtil, attributes, 0.0f)
        view.layoutParams = layoutParams
    }


    // --
    // Viewlet property helpers
    // --

    fun optionalHorizontalGravity(mapUtil: InflatorMapUtil, attributes: Map<String, Any>, defaultValue: Float, key: String = "horizontalGravity", combinedKey: String = "gravity"): Float {
        // Extract horizontal gravity from shared horizontal/vertical string
        var gravityString: String? = null
        if (attributes[combinedKey] is String) {
            gravityString = attributes[combinedKey] as String
        }
        if (gravityString != null) {
            if (gravityString == "center" || gravityString == "centerHorizontal") {
                return 0.5f
            } else if (gravityString == "left") {
                return 0.0f
            } else if (gravityString == "right") {
                return 1.0f
            }
            return defaultValue
        }

        // Check horizontal gravity being specified separately
        var horizontalGravityString: String? = null
        if (attributes[key] is String) {
            horizontalGravityString = attributes[key] as String
        }
        if (horizontalGravityString != null) {
            return when (horizontalGravityString) {
                "center" -> 0.5f
                "left" -> 0.0f
                "right" -> 1.0f
                else -> defaultValue
            }
        }
        return mapUtil.optionalFloat(attributes, key, defaultValue)
    }

    fun optionalVerticalGravity(mapUtil: InflatorMapUtil, attributes: Map<String, Any>, defaultValue: Float, key: String = "verticalGravity", combinedKey: String = "gravity"): Float {
        // Extract horizontal gravity from shared horizontal/vertical string
        var gravityString: String? = null
        if (attributes[combinedKey] is String) {
            gravityString = attributes[combinedKey] as String
        }
        if (gravityString != null) {
            if (gravityString == "center" || gravityString == "centerVertical") {
                return 0.5f
            } else if (gravityString == "top") {
                return 0.0f
            } else if (gravityString == "bottom") {
                return 1.0f
            }
            return defaultValue
        }

        // Check horizontal gravity being specified separately
        var verticalGravityString: String? = null
        if (attributes[key] is String) {
            verticalGravityString = attributes[key] as String
        }
        if (verticalGravityString != null) {
            return when (verticalGravityString) {
                "center" -> 0.5f
                "top" -> 0.0f
                "bottom" -> 1.0f
                else -> defaultValue
            }
        }
        return mapUtil.optionalFloat(attributes, key, defaultValue)
    }

}
