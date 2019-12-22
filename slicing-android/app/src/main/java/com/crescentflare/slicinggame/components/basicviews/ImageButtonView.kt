package com.crescentflare.slicinggame.components.basicviews

import android.annotation.TargetApi
import android.content.Context
import android.graphics.Color
import android.os.Build
import android.util.AttributeSet
import android.view.View
import com.crescentflare.jsoninflator.JsonInflatable
import com.crescentflare.jsoninflator.binder.InflatorBinder
import com.crescentflare.jsoninflator.utility.InflatorMapUtil
import com.crescentflare.slicinggame.components.utility.ComponentStateDrawable
import com.crescentflare.slicinggame.components.utility.ImageSource
import com.crescentflare.slicinggame.components.utility.ViewletUtil
import com.crescentflare.slicinggame.infrastructure.events.AppEvent
import com.crescentflare.slicinggame.infrastructure.events.AppEventObserver
import com.crescentflare.unilayout.views.UniImageView
import java.lang.ref.WeakReference


/**
 * Basic view: an image which can be used as a button
 */
open class ImageButtonView : UniImageView, View.OnClickListener {

    // --
    // Static: viewlet integration
    // --

    companion object {

        val viewlet: JsonInflatable = object : JsonInflatable {
            override fun create(context: Context): Any {
                return ImageButtonView(context)
            }

            override fun update(mapUtil: InflatorMapUtil, obj: Any, attributes: Map<String, Any>, parent: Any?, binder: InflatorBinder?): Boolean {
                if (obj is ImageButtonView) {
                    // Apply image
                    val stretchType = ImageView.StretchType.fromString(mapUtil.optionalString(attributes, "stretchType", ""))
                    obj.scaleType = stretchType.toScaleType()
                    obj.source = ImageSource.fromValue(attributes["source"])
                    obj.highlightedSource = ImageSource.fromValue(attributes["highlightedSource"])
                    obj.disabledSource = ImageSource.fromValue(attributes["disabledSource"])

                    // Apply colorization
                    obj.colorize = mapUtil.optionalColor(attributes, "colorize", Color.TRANSPARENT)
                    obj.highlightedColorize = mapUtil.optionalColor(attributes, "highlightedColorize", Color.TRANSPARENT)
                    obj.disabledColorize = mapUtil.optionalColor(attributes, "disabledColorize", Color.TRANSPARENT)

                    // Generic view properties
                    ViewletUtil.applyGenericViewAttributes(mapUtil, obj, attributes)

                    // Apply event
                    obj.tapEvent = AppEvent.fromValue(attributes["tapEvent"])

                    // Chain event observer
                    if (parent is AppEventObserver) {
                        obj.eventObserver = parent
                    }
                    return true
                }
                return false
            }

            override fun canRecycle(mapUtil: InflatorMapUtil, obj: Any, attributes: Map<String, Any>): Boolean {
                return obj::class == ImageButtonView::class
            }
        }
    }


    // --
    // Members
    // --

    private val stateDrawable = ComponentStateDrawable()
    private var eventObserverReference : WeakReference<AppEventObserver>? = null


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
        setImageDrawable(stateDrawable)
    }


    // --
    // Configurable values
    // --

    var eventObserver: AppEventObserver?
        get() = eventObserverReference?.get()
        set(newValue) {
            eventObserverReference = if (newValue != null) {
                WeakReference(newValue)
            } else {
                null
            }
        }

    var tapEvent: AppEvent? = null
        set(tapEvent) {
            field = tapEvent
            setOnClickListener(if (tapEvent != null) this else null)
        }

    var source: ImageSource? = null
        set(source) {
            if (field !== source) {
                field = source
                if (source != null) {
                    source.getDrawable(context) {
                        if (field === source) {
                            stateDrawable.drawable = it
                        }
                    }
                } else {
                    stateDrawable.drawable = null
                }
            }
        }

    var highlightedSource: ImageSource? = null
        set(highlightedSource) {
            if (field !== highlightedSource) {
                field = highlightedSource
                if (highlightedSource != null) {
                    highlightedSource.getDrawable(context) {
                        if (field === highlightedSource) {
                            stateDrawable.pressedDrawable = it
                        }
                    }
                } else {
                    stateDrawable.pressedDrawable = null
                }
            }
        }

    var disabledSource: ImageSource? = null
        set(disabledSource) {
            if (field !== disabledSource) {
                field = disabledSource
                if (disabledSource != null) {
                    disabledSource.getDrawable(context) {
                        if (field === disabledSource) {
                            stateDrawable.disabledDrawable = it
                        }
                    }
                } else {
                    stateDrawable.disabledDrawable = null
                }
            }
        }

    var colorize: Int?
        set(colorize) {
            stateDrawable.colorize = if (colorize == Color.TRANSPARENT) null else colorize
        }
        get() = stateDrawable.colorize

    var highlightedColorize: Int?
        set(highlightedColorize) {
            stateDrawable.pressedColorize = if (highlightedColorize == Color.TRANSPARENT) null else highlightedColorize
        }
        get() = stateDrawable.pressedColorize

    var disabledColorize: Int?
        set(disabledColorize) {
            stateDrawable.disabledColorize = if (disabledColorize == Color.TRANSPARENT) null else disabledColorize
        }
        get() = stateDrawable.disabledColorize


    // --
    // Interaction
    // --

    override fun onClick(view: View?) {
        tapEvent?.let {
            eventObserver?.observedEvent(it, this)
        }
    }

}
