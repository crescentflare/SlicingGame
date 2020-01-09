package com.crescentflare.slicinggame.components.containers

import android.annotation.TargetApi
import android.content.Context
import android.content.res.Resources
import android.os.Build
import android.util.AttributeSet
import android.util.TypedValue
import android.view.View
import android.view.ViewGroup
import android.widget.ScrollView
import com.crescentflare.jsoninflator.JsonInflatable
import com.crescentflare.jsoninflator.binder.InflatorBinder
import com.crescentflare.jsoninflator.utility.InflatorMapUtil
import com.crescentflare.slicinggame.R
import com.crescentflare.slicinggame.components.types.NavigationBarComponent
import com.crescentflare.slicinggame.components.utility.ViewletUtil
import com.crescentflare.unilayout.helpers.UniLayout
import com.crescentflare.unilayout.helpers.UniLayoutParams

/**
 * Container view: layout for the entire page, makes it easier to handle safe areas
 */
class PageContainerView: ViewGroup {

    // --
    // Static: viewlet integration
    // --

    companion object {

        val viewlet: JsonInflatable = object : JsonInflatable {
            override fun create(context: Context): Any {
                return PageContainerView(context)
            }

            override fun update(mapUtil: InflatorMapUtil, obj: Any, attributes: Map<String, Any>, parent: Any?, binder: InflatorBinder?): Boolean {
                if (obj is PageContainerView) {
                    // Set title bar
                    val titleBarResult = ViewletUtil.createChildViewItem(mapUtil, obj.titleBarView, obj, attributes, attributes["titleBar"], binder)
                    if (!titleBarResult.isRecycled(0)) {
                        obj.titleBarView = titleBarResult.items.firstOrNull() as? View
                    }

                    // Set background item
                    val backgroundItemResult = ViewletUtil.createChildViewItem(mapUtil, obj.backgroundItemView, obj, attributes, attributes["backgroundItem"], binder)
                    if (!backgroundItemResult.isRecycled(0)) {
                        obj.backgroundItemView = backgroundItemResult.items.firstOrNull() as? View
                        (obj.backgroundItemView as? ViewGroup)?.let {
                            it.clipChildren = false
                            it.clipToPadding = false
                        }
                    }

                    // Create or update content items
                    ViewletUtil.createChildViews(mapUtil, obj.contentContainer, obj, attributes, attributes["contentItems"], binder)
                    for (i in 0 until obj.contentContainer.childCount) {
                        val child = obj.contentContainer.getChildAt(i)
                        if (child is ViewGroup) {
                            if (child is ScrollView) {
                                child.clipChildren = false
                            }
                            child.clipToPadding = false
                        }
                    }

                    // Generic view properties
                    ViewletUtil.applyGenericViewAttributes(mapUtil, obj, attributes)
                    return true
                }
                return false
            }

            override fun canRecycle(mapUtil: InflatorMapUtil, obj: Any, attributes: Map<String, Any>): Boolean {
                return obj::class == PageContainerView::class
            }
        }
    }


    // --
    // Members
    // --

    private var contentContainer: FrameContainerView


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
        // Disable clipping to allow content view drawing to go out of bounds under the transparent bars
        clipToPadding = false
        clipChildren = false

        // Add content container, disable clipping as well
        contentContainer = FrameContainerView(context)
        addView(contentContainer)
        contentContainer.clipToPadding = false
        contentContainer.clipChildren = false
    }


    // --
    // Manage views
    // --

    var titleBarView: View? = null
        set(titleBarView) {
            if (field != null) {
                removeView(field)
            }
            field = titleBarView
            if (field != null) {
                addView(field)
            }
        }

    var backgroundItemView: View? = null
        set(backgroundView) {
            if (field != null) {
                removeView(field)
            }
            field = backgroundView
            if (field != null) {
                if (backgroundView is ViewGroup) {
                    backgroundView.clipChildren = false
                    backgroundView.clipToPadding = false
                }
                addView(field, 0)
            }
        }

    fun addContentView(view: View) {
        if (view is ViewGroup) {
            if (view is ScrollView) {
                view.clipChildren = false
            }
            view.clipToPadding = false
        }
        contentContainer.addView(view)
    }

    fun removeContentView(view: View) {
        if (view.parent == contentContainer) {
            contentContainer.removeView(view)
        }
    }

    fun removeAllContentViews() {
        contentContainer.removeAllViews()
    }


    // --
    // Handle insets
    // --

    private var cachedActionBarHeight = 0
    private var cachedActionBarHeightHash = 0

    private val transparentStatusBarHeight: Int
        get() = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) rootWindowInsets?.stableInsetTop ?: 0 else 0

    private val transparentBottomBarHeight: Int
        get() = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && Resources.getSystem().displayMetrics.widthPixels < Resources.getSystem().displayMetrics.heightPixels) rootWindowInsets?.stableInsetBottom ?: 0 else 0

    private val actionBarHeight: Int
        get() {
            val newHash = width * 256 + height
            if (cachedActionBarHeight == 0 || newHash != cachedActionBarHeightHash) {
                val typedValue = TypedValue()
                cachedActionBarHeight = if (context.theme.resolveAttribute(R.attr.actionBarSize, typedValue, true)) TypedValue.complexToDimensionPixelSize(typedValue.data, Resources.getSystem().displayMetrics) else 0
                cachedActionBarHeightHash = newHash
            }
            return cachedActionBarHeight
        }


    // --
    // Custom layout
    // --

    override fun onMeasure(widthMeasureSpec: Int, heightMeasureSpec: Int) {
        val width = MeasureSpec.getSize(widthMeasureSpec)
        val height = MeasureSpec.getSize(heightMeasureSpec)
        val widthMode = MeasureSpec.getMode(widthMeasureSpec)
        val heightMode = MeasureSpec.getMode(heightMeasureSpec)
        if (widthMode == MeasureSpec.EXACTLY && heightMode == MeasureSpec.EXACTLY) {
            // Update and measure title bar
            var topInset = 0
            (titleBarView as? NavigationBarComponent)?.let {
                topInset = actionBarHeight
                it.statusBarHeight = transparentStatusBarHeight
                it.barContentHeight = actionBarHeight
            }
            val titleBarHeight = titleBarView?.layoutParams?.height ?: LayoutParams.WRAP_CONTENT
            if (titleBarHeight >= 0) {
                titleBarView?.measure(MeasureSpec.makeMeasureSpec(width, MeasureSpec.EXACTLY), MeasureSpec.makeMeasureSpec(titleBarHeight, MeasureSpec.EXACTLY))
            } else {
                titleBarView?.measure(MeasureSpec.makeMeasureSpec(width, MeasureSpec.EXACTLY), MeasureSpec.makeMeasureSpec(0, MeasureSpec.UNSPECIFIED))
            }
            titleBarView?.measure(MeasureSpec.makeMeasureSpec(width, MeasureSpec.EXACTLY), MeasureSpec.makeMeasureSpec(titleBarView?.measuredHeight ?: 0, MeasureSpec.EXACTLY))
            if (topInset == 0) {
                topInset = titleBarView?.measuredHeight ?: 0
            }

            // Measure content and background
            contentContainer.measure(MeasureSpec.makeMeasureSpec(width, MeasureSpec.EXACTLY), MeasureSpec.makeMeasureSpec(height - topInset, MeasureSpec.EXACTLY))
            backgroundItemView?.let {
                var limitWidth = width
                var limitHeight = height + transparentStatusBarHeight + transparentBottomBarHeight
                (it.layoutParams as? MarginLayoutParams)?.let { layoutParams ->
                    limitWidth -= layoutParams.leftMargin + layoutParams.rightMargin
                    limitHeight -= layoutParams.topMargin + layoutParams.bottomMargin
                }
                val widthMeasureMode = if (it.layoutParams.width == LayoutParams.MATCH_PARENT) MeasureSpec.EXACTLY else MeasureSpec.AT_MOST
                val heightMeasureMode = if (it.layoutParams.height == LayoutParams.MATCH_PARENT) MeasureSpec.EXACTLY else MeasureSpec.AT_MOST
                UniLayout.measure(it, limitWidth, limitHeight, widthMeasureMode, heightMeasureMode, MeasureSpec.UNSPECIFIED, MeasureSpec.UNSPECIFIED)
            }
            setMeasuredDimension(width, height)
        } else {
            super.onMeasure(widthMeasureSpec, heightMeasureSpec)
        }
    }

    override fun onLayout(changed: Boolean, left: Int, top: Int, right: Int, bottom: Int) {
        val topInset = if (titleBarView is NavigationBarComponent) actionBarHeight else titleBarView?.measuredHeight ?: 0
        titleBarView?.layout(0, -transparentStatusBarHeight, right - left, (titleBarView?.measuredHeight ?: 0) - transparentStatusBarHeight)
        contentContainer.layout(0, topInset, right - left, bottom - top)
        backgroundItemView?.let {
            var x = 0
            var y = -transparentStatusBarHeight
            val viewWidth = it.measuredWidth
            val viewHeight = it.measuredHeight
            (it.layoutParams as? MarginLayoutParams)?.let { layoutParams ->
                x += layoutParams.leftMargin
                y += layoutParams.topMargin
            }
            (it.layoutParams as? UniLayoutParams)?.let { layoutParams ->
                x += ((right - left - viewWidth).toFloat() * layoutParams.horizontalGravity).toInt()
                y += ((bottom - top - viewHeight).toFloat() * layoutParams.verticalGravity).toInt()
            }
            it.layout(x, y, x + viewWidth, y + viewHeight)
        }
    }

}
