package com.crescentflare.slicinggame.sprites.core

import android.graphics.Color
import android.graphics.PointF
import android.graphics.RectF
import com.crescentflare.slicinggame.infrastructure.geometry.Vector
import com.crescentflare.slicinggame.infrastructure.physics.Physics
import com.crescentflare.slicinggame.infrastructure.physics.PhysicsObject
import kotlin.math.abs
import kotlin.random.Random

/**
 * Sprite core: a single sprite within a sprite container
 */
class Sprite: PhysicsObject {

    // --
    // Members
    // --

    override var x = 0f
    override var y = 0f
    var width = 1f
    var height = 1f
    override var recursiveCheck = 0
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

    override val collisionBounds: RectF
        get() = RectF(0f, 0f, width, height)


    // --
    // Movement
    // --

    fun update(timeInterval: Float, physics: Physics) {
        physics.moveObject(this, moveX * timeInterval, moveY * timeInterval, timeInterval)
    }


    // --
    // Physics
    // --

    override fun onCollision(hitObject: PhysicsObject?, side: Physics.CollisionSide, timeRemaining: Float, physics: Physics) {
        when (side) {
            Physics.CollisionSide.Left -> moveX = abs(moveX)
            Physics.CollisionSide.Right -> moveX = -abs(moveX)
            Physics.CollisionSide.Top -> moveY = abs(moveY)
            Physics.CollisionSide.Bottom -> moveY = -abs(moveY)
        }
        if (timeRemaining > 0) {
            update(timeRemaining, physics)
        }
    }


    // --
    // Drawing
    // --

    fun draw(canvas: SpriteCanvas) {
        canvas.fillRect(x, y, width, height, Color.BLACK)
    }

}
