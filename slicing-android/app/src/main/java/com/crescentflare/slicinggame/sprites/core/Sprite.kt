package com.crescentflare.slicinggame.sprites.core

import android.graphics.Color

/**
 * Sprite core: a single sprite within a sprite container
 */
class Sprite {

    // --
    // Members
    // --

    var x = 0f
    var y = 0f
    var width = 1f
    var height = 1f


    // --
    // Initialization
    // --

    init {
        // No implementation
    }


    // --
    // Drawing
    // --

    fun draw(canvas: SpriteCanvas) {
        canvas.fillRect(x, y, width, height, Color.BLACK)
    }

}
