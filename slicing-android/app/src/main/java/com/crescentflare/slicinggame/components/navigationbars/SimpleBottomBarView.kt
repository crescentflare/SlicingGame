package com.crescentflare.slicinggame.components.navigationbars

import android.annotation.TargetApi
import android.content.Context
import android.graphics.drawable.ColorDrawable
import android.os.Build
import android.util.AttributeSet
import com.crescentflare.jsoninflator.JsonInflatable
import com.crescentflare.jsoninflator.binder.InflatorBinder
import com.crescentflare.jsoninflator.utility.InflatorMapUtil
import com.crescentflare.slicinggame.components.types.NavigationBarComponent
import com.crescentflare.slicinggame.components.utility.ViewletUtil
import com.crescentflare.unilayout.views.UniView


/**
 * Navigation bar: used to colorize the space under the bottom navigation bar controls (like home, back, etc.)
 */
open class SimpleBottomBarView : UniView, NavigationBarComponent {

    // --
    // Statics
    // --

    companion object {

        // --
        // Static: viewlet integration
        // --

        val viewlet: JsonInflatable = object : JsonInflatable {
            override fun create(context: Context): Any {
                return SimpleBottomBarView(context)
            }

            override fun update(mapUtil: InflatorMapUtil, obj: Any, attributes: Map<String, Any>, parent: Any?, binder: InflatorBinder?): Boolean {
                if (obj is SimpleBottomBarView) {
                    ViewletUtil.applyGenericViewAttributes(mapUtil, obj, attributes)
                    return true
                }
                return false
            }

            override fun canRecycle(mapUtil: InflatorMapUtil, obj: Any, attributes: Map<String, Any>): Boolean {
                return obj::class == SimpleBottomBarView::class
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
    // NavigationBarComponent implementation
    // --

    override val averageColor: Int?
        get() = (background as? ColorDrawable)?.color

    override var statusBarHeight: Int = 0
    override var barContentHeight: Int = 0

}
