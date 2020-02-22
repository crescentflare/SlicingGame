package com.crescentflare.slicinggame.infrastructure.inflator

import com.crescentflare.jsoninflator.JsonInflator

/**
 * Inflator: a list of json inflators, like viewlet creator
 */
object Inflators {

    val viewlet = JsonInflator("viewlet", "viewletStyle")

}
