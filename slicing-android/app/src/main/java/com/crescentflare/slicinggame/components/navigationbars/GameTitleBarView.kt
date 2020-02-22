package com.crescentflare.slicinggame.components.navigationbars

import android.annotation.TargetApi
import android.content.Context
import android.graphics.Color
import android.graphics.drawable.ColorDrawable
import android.os.Build
import android.util.AttributeSet
import android.view.View
import androidx.core.content.ContextCompat
import com.crescentflare.jsoninflator.JsonInflatable
import com.crescentflare.jsoninflator.JsonLoader
import com.crescentflare.jsoninflator.binder.InflatableRef
import com.crescentflare.jsoninflator.binder.InflatorAnnotationBinder
import com.crescentflare.jsoninflator.binder.InflatorBinder
import com.crescentflare.jsoninflator.utility.InflatorMapUtil
import com.crescentflare.slicinggame.R
import com.crescentflare.slicinggame.components.basicviews.TextView
import com.crescentflare.slicinggame.components.containers.LinearContainerView
import com.crescentflare.slicinggame.components.types.NavigationBarComponent
import com.crescentflare.slicinggame.components.utility.ViewletUtil
import com.crescentflare.slicinggame.infrastructure.coreextensions.colorIntensity
import com.crescentflare.slicinggame.infrastructure.coreextensions.localized


/**
 * Navigation bar: the title bar for in-game
 */
open class GameTitleBarView : LinearContainerView, NavigationBarComponent {

    // --
    // Statics
    // --

    companion object {

        // --
        // Static: reference to layout resource
        // --

        private const val layoutResource = R.raw.game_title_bar


        // --
        // Static: viewlet integration
        // --

        val viewlet: JsonInflatable = object : JsonInflatable {
            override fun create(context: Context): Any {
                return GameTitleBarView(context)
            }

            override fun update(mapUtil: InflatorMapUtil, obj: Any, attributes: Map<String, Any>, parent: Any?, binder: InflatorBinder?): Boolean {
                if (obj is GameTitleBarView) {
                    // Apply title
                    obj.title = mapUtil.optionalString(attributes, "localizedTitle", null)?.localized(obj.context) ?: mapUtil.optionalString(attributes, "title", null)

                    // Apply bar styling
                    obj.showDivider = mapUtil.optionalBoolean(attributes, "showDivider", false)

                    // Generic view properties
                    ViewletUtil.applyGenericViewAttributes(mapUtil, obj, attributes)
                    return true
                }
                return false
            }

            override fun canRecycle(mapUtil: InflatorMapUtil, obj: Any, attributes: Map<String, Any>): Boolean {
                return obj::class == GameTitleBarView::class
            }
        }
    }


    // --
    // Bound views
    // --

    @InflatableRef("statusUnderlay")
    private var statusUnderlayView: View? = null

    @InflatableRef("content")
    private var contentView: View? = null

    @InflatableRef("title")
    private var titleView: TextView? = null

    @InflatableRef("divider")
    private var dividerView: View? = null


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
        ViewletUtil.assertInflateOn(this, JsonLoader.instance.loadAttributes(context, layoutResource),null, InflatorAnnotationBinder(this))
    }


    // --
    // Configurable values
    // --

    override fun setBackgroundColor(color: Int) {
        statusUnderlayView?.setBackgroundColor(color)
        contentView?.setBackgroundColor(color)
        titleView?.setTextColor(if (averageColor?.colorIntensity() ?: 0.0 < 0.25) Color.WHITE else ContextCompat.getColor(context, R.color.text))
    }

    var title: String?
        get() = titleView?.text?.toString()
        set(title) {
            titleView?.text = title
        }

    var showDivider: Boolean = false
        set(showDivider) {
            field = showDivider
            dividerView?.visibility = if (showDivider) VISIBLE else GONE
        }


    // --
    // NavigationBarComponent implementation
    // --

    override val averageColor: Int?
        get() = (contentView?.background as? ColorDrawable)?.color

    override var statusBarHeight: Int = 0
        set(statusBarHeight) {
            field = statusBarHeight
            statusUnderlayView?.layoutParams?.height = statusBarHeight
        }

    override var barContentHeight: Int = 0
        set(barContentHeight) {
            field = barContentHeight
            contentView?.layoutParams?.height = barContentHeight
        }

}
