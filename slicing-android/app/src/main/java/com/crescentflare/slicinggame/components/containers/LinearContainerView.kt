package com.crescentflare.slicinggame.components.containers

import android.annotation.TargetApi
import android.content.Context
import android.os.Build
import android.util.AttributeSet
import com.crescentflare.jsoninflator.JsonInflatable
import com.crescentflare.jsoninflator.binder.InflatorBinder
import com.crescentflare.jsoninflator.utility.InflatorMapUtil
import com.crescentflare.slicinggame.components.utility.ViewletUtil
import com.crescentflare.slicinggame.infrastructure.events.AppEvent
import com.crescentflare.slicinggame.infrastructure.events.AppEventObserver
import com.crescentflare.unilayout.containers.UniLinearContainer
import java.lang.ref.WeakReference

/**
 * Container view: basic layout container for horizontally or vertically aligned views
 */
open class LinearContainerView : UniLinearContainer, AppEventObserver {

    // --
    // Static: viewlet integration
    // --

    companion object {

        val viewlet: JsonInflatable = object : JsonInflatable {
            override fun create(context: Context): Any {
                return LinearContainerView(context)
            }

            override fun update(mapUtil: InflatorMapUtil, obj: Any, attributes: Map<String, Any>, parent: Any?, binder: InflatorBinder?): Boolean {
                if (obj is LinearContainerView) {
                    // Orientation
                    val orientationString = mapUtil.optionalString(attributes, "orientation", "")
                    if (orientationString == "horizontal") {
                        obj.orientation = HORIZONTAL
                    } else {
                        obj.orientation = VERTICAL
                    }

                    // Create or update children
                    ViewletUtil.createChildViews(mapUtil, obj, obj, attributes, attributes["items"], binder)

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
                return obj::class == LinearContainerView::class
            }
        }
    }


    // --
    // Members
    // --

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
        orientation = VERTICAL
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


    // --
    // Interaction
    // --

    override fun observedEvent(event: AppEvent, sender: Any?) {
        eventObserver?.observedEvent(event, sender)
    }

}
