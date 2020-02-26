package com.crescentflare.slicinggame.sprites.core

import android.graphics.Color
import android.graphics.PointF
import android.graphics.RectF
import com.crescentflare.slicinggame.infrastructure.geometry.Vector
import com.crescentflare.slicinggame.infrastructure.physics.Physics
import com.crescentflare.slicinggame.infrastructure.physics.PhysicsObject
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
    var rotation = 0f
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
        rotation = Random.nextFloat() * 360
    }


    // --
    // Collision properties
    // --

    override val collisionBounds: RectF
        get() = RectF(0f, 0f, width, height)

    override val collisionRotation: Float
        get() = rotation

    override val collisionPivot: PointF
        get() = PointF(width / 2, height / 2)


    // --
    // Movement
    // --

    fun update(timeInterval: Float, physics: Physics) {
        physics.moveObject(this, moveX * timeInterval, moveY * timeInterval, timeInterval)
    }


    // --
    // Physics
    // --

    override fun onCollision(hitObject: PhysicsObject?, normal: Vector, timeRemaining: Float, physics: Physics) {
        val dotProduct = normal.x * moveX + normal.y * moveY
        val newMoveX = moveX - 2 * normal.x * dotProduct
        val newMoveY = moveY - 2 * normal.y * dotProduct
        val surfaceVector = normal.perpendicular().reversed()
        if (surfaceVector.directionOfPoint(PointF(newMoveX, newMoveY)) <= 0) {
            moveX = newMoveX
            moveY = newMoveY
        }
        if (timeRemaining > 0) {
            update(timeRemaining, physics)
        }
    }


    // --
    // Drawing
    // --

    fun draw(canvas: SpriteCanvas) {
        canvas.fillRotatedRect(x + width / 2, y + height / 2, width, height, Color.BLACK, rotation)
    }

}
