package com.crescentflare.slicinggame.components.navigationbars

import android.annotation.TargetApi
import android.content.Context
import android.content.res.Resources
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
import com.crescentflare.slicinggame.components.basicviews.ImageButtonView
import com.crescentflare.slicinggame.components.basicviews.TextView
import com.crescentflare.slicinggame.components.containers.LinearContainerView
import com.crescentflare.slicinggame.components.types.NavigationBarComponent
import com.crescentflare.slicinggame.components.utility.ImageSource
import com.crescentflare.slicinggame.components.utility.ViewletUtil
import com.crescentflare.slicinggame.infrastructure.coreextensions.colorIntensity
import com.crescentflare.slicinggame.infrastructure.coreextensions.localized
import com.crescentflare.slicinggame.infrastructure.events.AppEvent
import com.crescentflare.slicinggame.infrastructure.events.AppEventObserver


/**
 * Navigation bar: the title bar for in-game
 */
open class GameTitleBarView : LinearContainerView, View.OnClickListener, NavigationBarComponent {

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

                    // Apply icons and events
                    obj.menuIcon = ImageSource.fromValue(attributes["menuIcon"])
                    obj.menuEvent = AppEvent.fromValue(attributes["menuEvent"])
                    obj.actionIcon = ImageSource.fromValue(attributes["actionIcon"])
                    obj.actionEvent = AppEvent.fromValue(attributes["actionEvent"])

                    // Apply bar styling
                    obj.showDivider = mapUtil.optionalBoolean(attributes, "showDivider", false)

                    // Generic view properties
                    ViewletUtil.applyGenericViewAttributes(mapUtil, obj, attributes)

                    // Chain event observer
                    if (parent is AppEventObserver) {
                        obj.eventObserver = parent
                    }
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

    @InflatableRef("menuIconContainer")
    private var menuIconContainer: View? = null

    @InflatableRef("menuIcon")
    private var menuIconView: ImageButtonView? = null

    @InflatableRef("actionIconContainer")
    private var actionIconContainer: View? = null

    @InflatableRef("actionIcon")
    private var actionIconView: ImageButtonView? = null

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
        menuIconView?.isClickable = false
        actionIconView?.isClickable = false
    }


    // --
    // Configurable values
    // --

    override fun setBackgroundColor(color: Int) {
        // Apply color to bar
        statusUnderlayView?.setBackgroundColor(color)
        contentView?.setBackgroundColor(color)

        // Colorize title components
        val darkBar = averageColor?.colorIntensity() ?: 0.0 < 0.25
        val titleColor = if (darkBar) Color.WHITE else ContextCompat.getColor(context, R.color.text)
        menuIconContainer?.setBackgroundResource(if (darkBar) R.drawable.title_bar_highlight_white else R.drawable.title_bar_highlight_black)
        actionIconContainer?.setBackgroundResource(if (darkBar) R.drawable.title_bar_highlight_white else R.drawable.title_bar_highlight_black)
        titleView?.setTextColor(titleColor)
        menuIconView?.colorize = titleColor
        actionIconView?.colorize = titleColor
        menuIconView?.disabledColorize = (titleColor and 0xffffff) + 0x40000000
        actionIconView?.disabledColorize = (titleColor and 0xffffff) + 0x40000000
    }

    var title: String?
        get() = titleView?.text?.toString()
        set(title) {
            titleView?.text = title
        }

    var menuIcon: ImageSource?
        get() = menuIconView?.source
        set(menuIcon) {
            val sideTitlePadding = (Resources.getSystem().displayMetrics.density * 16).toInt()
            menuIconView?.source = menuIcon
            titleView?.setPadding(if (menuIcon != null) 0 else sideTitlePadding, 0, if (actionIcon != null) 0 else sideTitlePadding, 0)
            menuIconContainer?.visibility = if (menuIcon != null) VISIBLE else GONE
        }

    var menuEvent: AppEvent? = null
        set(menuEvent) {
            field = menuEvent
            menuIconView?.isEnabled = menuEvent != null
            menuIconContainer?.isEnabled = menuEvent != null
            menuIconContainer?.setOnClickListener(if (menuEvent != null) this else null)
        }

    var actionIcon: ImageSource?
        get() = actionIconView?.source
        set(actionIcon) {
            val sideTitlePadding = (Resources.getSystem().displayMetrics.density * 16).toInt()
            actionIconView?.source = actionIcon
            titleView?.setPadding(if (menuIcon != null) 0 else sideTitlePadding, 0, if (actionIcon != null) 0 else sideTitlePadding, 0)
            actionIconContainer?.visibility = if (actionIcon != null) VISIBLE else GONE
        }

    var actionEvent: AppEvent? = null
        set(actionEvent) {
            field = actionEvent
            actionIconView?.isEnabled = actionEvent != null
            actionIconContainer?.isEnabled = actionEvent != null
            actionIconContainer?.setOnClickListener(if (actionEvent != null) this else null)
        }

    var showDivider: Boolean = false
        set(showDivider) {
            field = showDivider
            dividerView?.visibility = if (showDivider) VISIBLE else GONE
        }


    // --
    // Interaction
    // --

    override fun onClick(view: View?) {
        if (view == menuIconContainer) {
            menuEvent?.let {
                eventObserver?.observedEvent(it, menuIconView)
            }
        } else if (view == actionIconContainer) {
            actionEvent?.let {
                eventObserver?.observedEvent(it, actionIconView)
            }
        }
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
            menuIconContainer?.layoutParams?.width = barContentHeight * 2 + barContentHeight / 8
            menuIconContainer?.layoutParams?.height = barContentHeight * 2
            (menuIconContainer?.layoutParams as? MarginLayoutParams)?.let {
                it.topMargin = -barContentHeight / 2
                it.bottomMargin = -barContentHeight / 2
                it.leftMargin = -barContentHeight
            }
            menuIconContainer?.setPadding(barContentHeight, barContentHeight / 2, barContentHeight / 8, barContentHeight / 2)
            actionIconContainer?.layoutParams?.width = barContentHeight * 2 + barContentHeight / 8
            actionIconContainer?.layoutParams?.height = barContentHeight * 2
            (actionIconContainer?.layoutParams as? MarginLayoutParams)?.let {
                it.topMargin = -barContentHeight / 2
                it.bottomMargin = -barContentHeight / 2
                it.rightMargin = -barContentHeight
            }
            actionIconContainer?.setPadding(barContentHeight / 8, barContentHeight / 2, barContentHeight, barContentHeight / 2)
        }

}
