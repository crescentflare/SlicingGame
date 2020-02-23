package com.crescentflare.slicinggame.sprites.core

import android.graphics.Color
import android.graphics.PointF
import android.graphics.RectF
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
    // Properties
    // --

    val bounds: RectF
        get() = RectF(x, y, x + width, y + height)


    // --
    // Movement
    // --

    fun update(timeInterval: Float, gridWidth: Float, gridHeight: Float, sprites: List<Sprite>) {
        // Apply movement
        x += moveX * timeInterval
        y += moveY * timeInterval

        // Handle collision against the level boundaries
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

        // Handle collision against other sprites
        val checkBounds = bounds
        for (sprite in sprites) {
            if (sprite !== this) {
                val spriteBounds = sprite.bounds
                if (checkBounds.intersects(spriteBounds.left, spriteBounds.top, spriteBounds.right, spriteBounds.bottom)) {
                    if (checkBounds.left < spriteBounds.left && moveX > 0) {
                        moveX = -moveX
                    } else if (checkBounds.right > spriteBounds.right && moveX < 0) {
                        moveX = -moveX
                    } else if (checkBounds.top < spriteBounds.top && moveY > 0) {
                        moveY = -moveY
                    } else if (checkBounds.bottom > spriteBounds.bottom && moveY < 0) {
                        moveY = -moveY
                    }
                }
            }
        }
    }


    // --
    // Drawing
    // --

    fun draw(canvas: SpriteCanvas) {
        canvas.fillRect(x, y, width, height, Color.BLACK)
    }

}
