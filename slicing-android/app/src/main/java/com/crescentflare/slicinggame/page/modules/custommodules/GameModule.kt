package com.crescentflare.slicinggame.page.modules.custommodules

import android.content.Context
import com.crescentflare.jsoninflator.JsonInflatable
import com.crescentflare.jsoninflator.binder.InflatorBinder
import com.crescentflare.jsoninflator.utility.InflatorMapUtil
import com.crescentflare.slicinggame.components.containers.GameContainerView
import com.crescentflare.slicinggame.components.utility.ImageSource
import com.crescentflare.slicinggame.infrastructure.events.AppEvent
import com.crescentflare.slicinggame.page.activities.PageActivity
import com.crescentflare.slicinggame.page.modules.PageModule

/**
 * Custom module: handles custom logic on the game page
 */
class GameModule: PageModule {

    // --
    // Static: inflatable integration
    // --

    companion object {

        val inflatable: JsonInflatable = object : JsonInflatable {

            override fun create(context: Context): Any {
                return GameModule()
            }

            override fun update(mapUtil: InflatorMapUtil, obj: Any, attributes: Map<String, Any>, parent: Any?, binder: InflatorBinder?): Boolean {
                if (obj is GameModule) {
                    // Apply component reference
                    val layoutBinder = (parent as? PageActivity)?.binder
                    val component = layoutBinder?.findByReference(mapUtil.optionalString(attributes, "gameContainer", null) ?: "")
                    obj.gameContainer = component as? GameContainerView

                    // Apply random backgrounds
                    val randomBackgrounds = mutableListOf<ImageSource>()
                    mapUtil.optionalObjectList(attributes, "randomBackgrounds").forEach {
                        val randomBackground = ImageSource.fromValue(it)
                        if (randomBackground != null) {
                            randomBackgrounds.add(randomBackground)
                        }
                    }
                    obj.randomBackgrounds = randomBackgrounds
                    return true
                }
                return false
            }

            override fun canRecycle(mapUtil: InflatorMapUtil, obj: Any, attributes: Map<String, Any>): Boolean {
                return obj::class == GameModule::class
            }

        }

    }


    // --
    // Members
    // --

    override val handleEventTypes = listOf("game")
    private var currentBackground = 0
    private var shuffledBackgrounds: List<ImageSource> = emptyList()


    // --
    // Configurable values
    // --

    var gameContainer: GameContainerView? = null
        set(gameContainer) {
            if (gameContainer !== field && currentBackground < shuffledBackgrounds.size) {
                gameContainer?.backgroundImage = shuffledBackgrounds[currentBackground]
            }
            field = gameContainer
        }

    var randomBackgrounds: List<ImageSource> = emptyList()
        set(randomBackgrounds) {
            if (randomBackgrounds != field && randomBackgrounds.isNotEmpty()) {
                currentBackground = 0
                shuffledBackgrounds = randomBackgrounds.shuffled()
                gameContainer?.backgroundImage = shuffledBackgrounds[currentBackground]
            }
            field = randomBackgrounds
        }


    // --
    // Lifecycle
    // --

    override fun onCreate(activity: PageActivity) {
        // No implementation
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
        if (event.type == "game") {
            when (event.name) {
                "reset" -> {
                    gameContainer?.resetSlices()
                    if (shuffledBackgrounds.isNotEmpty()) {
                        currentBackground = (currentBackground + 1) % shuffledBackgrounds.size
                        gameContainer?.backgroundImage = shuffledBackgrounds[currentBackground]
                    }
                }
            }
            return true
        }
        return false
    }

}
