package com.crescentflare.slicinggame.infrastructure.events

/**
 * Event system: a protocol to observe for events
 */
interface AppEventObserver {

    fun observedEvent(event: AppEvent, sender: Any?)

}
