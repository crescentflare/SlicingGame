package com.crescentflare.slicinggame.sprites.core

import android.content.res.Resources
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint

/**
 * Sprite core: a single sprite within a sprite container
 */
class Sprite {

    // --
    // Members
    // --

    var x = 0f
    var y = 0f
    var width = 32f
    var height = 32f


    // --
    // Initialization
    // --

    init {
        // No implementation
    }


    // --
    // Drawing
    // --

    fun draw(canvas: Canvas, paint: Paint) {
        val density = Resources.getSystem().displayMetrics.density
        paint.color = Color.BLACK
        paint.style = Paint.Style.FILL
        canvas.drawRect(x * density, y * density, (x + width) * density, (y + height) * density, paint)
    }

}
