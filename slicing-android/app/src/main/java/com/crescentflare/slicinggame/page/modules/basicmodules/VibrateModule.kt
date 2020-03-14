package com.crescentflare.slicinggame.page.modules.basicmodules

import android.content.Context
import android.content.Context.VIBRATOR_SERVICE
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import com.crescentflare.jsoninflator.JsonInflatable
import com.crescentflare.jsoninflator.binder.InflatorBinder
import com.crescentflare.jsoninflator.utility.InflatorMapUtil
import com.crescentflare.slicinggame.infrastructure.events.AppEvent
import com.crescentflare.slicinggame.page.activities.PageActivity
import com.crescentflare.slicinggame.page.modules.PageModule
import java.lang.ref.WeakReference

/**
 * Basic module: catches events to vibrate the device
 */
class VibrateModule: PageModule {

    // --
    // Statics
    // --

    companion object {

        // --
        // Static: inflatable integration
        // --

        val inflatable: JsonInflatable = object : JsonInflatable {

            override fun create(context: Context): Any {
                return VibrateModule()
            }

            override fun update(mapUtil: InflatorMapUtil, obj: Any, attributes: Map<String, Any>, parent: Any?, binder: InflatorBinder?): Boolean {
                return obj is VibrateModule
            }

            override fun canRecycle(mapUtil: InflatorMapUtil, obj: Any, attributes: Map<String, Any>): Boolean {
                return obj::class == VibrateModule::class
            }

        }


        // --
        // Static: vibrate
        // --

        fun vibrate(context: Context, duration: Int) {
            val vibrator = context.getSystemService(VIBRATOR_SERVICE)
            (vibrator as? Vibrator)?.let {
                if (Build.VERSION.SDK_INT >= 26) {
                    it.vibrate(VibrationEffect.createOneShot(duration.toLong(), VibrationEffect.DEFAULT_AMPLITUDE));
                } else {
                    it.vibrate(duration.toLong());
                }
            }
        }

    }


    // --
    // Members
    // --

    override val handleEventTypes = listOf("vibrate")
    private var activityReference : WeakReference<PageActivity>? = null


    // --
    // Lifecycle
    // --

    override fun onCreate(activity: PageActivity) {
        activityReference = WeakReference(activity)
    }

    override fun onResume() {
        // No implementation
    }

    override fun onPause() {
        // No implementation
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
        if (event.type == "vibrate") {
            activityReference?.get()?.let {
                vibrate(it, 60)
            }
            return true
        }
        return false
    }

}
