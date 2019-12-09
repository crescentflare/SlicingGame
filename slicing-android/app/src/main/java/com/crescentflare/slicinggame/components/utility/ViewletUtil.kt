package com.crescentflare.slicinggame.components.utility

import android.content.Context
import android.view.View
import android.view.ViewGroup
import com.crescentflare.jsoninflator.JsonInflatable
import com.crescentflare.jsoninflator.binder.InflatableRef
import com.crescentflare.jsoninflator.binder.InflatorAnnotationBinder
import com.crescentflare.jsoninflator.binder.InflatorBinder
import com.crescentflare.jsoninflator.utility.InflatorMapUtil
import com.crescentflare.slicinggame.BuildConfig
import com.crescentflare.slicinggame.infrastructure.inflator.Inflators
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

}
