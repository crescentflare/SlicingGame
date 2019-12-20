package com.crescentflare.slicinggame.page.modules.basicmodules

import android.app.AlertDialog
import android.content.Context
import android.content.DialogInterface
import com.crescentflare.jsoninflator.JsonInflatable
import com.crescentflare.jsoninflator.binder.InflatorBinder
import com.crescentflare.jsoninflator.utility.InflatorMapUtil
import com.crescentflare.slicinggame.infrastructure.coreextensions.localized
import com.crescentflare.slicinggame.infrastructure.events.AppEvent
import com.crescentflare.slicinggame.page.activities.PageActivity
import com.crescentflare.slicinggame.page.modules.PageModule
import java.lang.ref.WeakReference

/**
 * Basic module: catches alert events to show popups
 */
class AlertModule: PageModule {

    // --
    // Statics
    // --

    companion object {

        // --
        // Static: inflatable integration
        // --

        val inflatable: JsonInflatable = object : JsonInflatable {

            override fun create(context: Context): Any {
                return AlertModule()
            }

            override fun update(mapUtil: InflatorMapUtil, obj: Any, attributes: Map<String, Any>, parent: Any?, binder: InflatorBinder?): Boolean {
                return obj is AlertModule
            }

            override fun canRecycle(mapUtil: InflatorMapUtil, obj: Any, attributes: Map<String, Any>): Boolean {
                return obj::class == AlertModule::class
            }

        }


        // --
        // Static: show alert popups
        // --

        fun showSimpleAlert(context: Context, title: String, text: String, actionText: String, completion: ((dialog: DialogInterface?, buttonId: Int) -> Unit)? = null) {
            val builder = AlertDialog.Builder(context)
                .setTitle(title)
                .setMessage(text)
                .setPositiveButton(actionText) { dialog, buttonId ->
                    completion?.invoke(dialog, buttonId)
                }
                .setOnCancelListener {
                    completion?.invoke(null, -1)
                }
            builder.show()
        }

    }


    // --
    // Members
    // --

    override val handleEventTypes = listOf("alert")
    private var activityReference : WeakReference<PageActivity>? = null
    private var queuedEvents = mutableListOf<AppEvent>()
    private var paused = true
    private var alertShown = false


    // --
    // Lifecycle
    // --

    override fun onCreate(activity: PageActivity) {
        activityReference = WeakReference(activity)
    }

    override fun onResume() {
        paused = false
        tryHandleQueuedEvent()
    }

    override fun onPause() {
        paused = true
    }

    override fun onDestroy() {
        // No implementation
    }

    override fun onLowMemory() {
        // No implementation
    }

    override fun onBackPressed(): Boolean {
        return false // No custom handling for the back button
    }


    // --
    // Event handling
    // --

    override fun handleEvent(event: AppEvent, sender: Any?): Boolean {
        if (event.type == "alert") {
            queuedEvents.add(event)
            tryHandleQueuedEvent()
            return true
        }
        return false
    }

    private fun tryHandleQueuedEvent() {
        if (!paused && !alertShown) {
            queuedEvents.firstOrNull()?.let {
                activityReference?.get()?.let { activity ->
                    val title = (it.parameters["localizedTitle"] as? String)?.localized(activity) ?: it.parameters["title"] as? String ?: "ALERT_UNSPECIFIED_TITLE".localized(activity)
                    val text = (it.parameters["localizedText"] as? String)?.localized(activity) ?: it.parameters["text"] as? String ?: "ALERT_UNSPECIFIED_TEXT".localized(activity)
                    val actionText = (it.parameters["localizedActionText"] as? String)?.localized(activity) ?: it.parameters["actionText"] as? String ?: "ALERT_OK".localized(activity)
                    queuedEvents.removeAt(0)
                    alertShown = true
                    showSimpleAlert(activity, title, text, actionText) { _, _ ->
                        alertShown = false
                        tryHandleQueuedEvent()
                    }
                }
            }
        }
    }

}
