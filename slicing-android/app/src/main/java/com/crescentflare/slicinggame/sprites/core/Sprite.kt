package com.crescentflare.slicinggame.sprites.core

import android.graphics.Color
import android.graphics.PointF
import com.crescentflare.slicinggame.infrastructure.geometry.Vector
import kotlin.random.Random

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
    private var moveX: Float
    private var moveY: Float


    // --
    // Initialization
    // --

    init {
        val moveVector = Vector(Random.nextFloat() * 360) * 4f
        moveX = moveVector.x
        moveY = moveVector.y
    }


    // --
    // Movement
    // --

    fun update(timeInterval: Float, gridWidth: Float, gridHeight: Float) {
        x += moveX * timeInterval
        y += moveY * timeInterval
        if (moveX > 0 && x + width > gridWidth) {
            x = gridWidth - width
            moveX = -moveX
        } else if (moveX < 0 && x < 0) {
            x = 0f
            moveX = -moveX
        }
        if (moveY > 0 && y + height > gridHeight) {
            y = gridHeight - height
            moveY = -moveY
        } else if (moveY < 0 && y < 0) {
            y = 0f
            moveY = -moveY
        }
    }


    // --
    // Drawing
    // --

    fun draw(canvas: SpriteCanvas) {
        canvas.fillRect(x, y, width, height, Color.BLACK)
    }

}
