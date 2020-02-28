package com.crescentflare.slicinggame.infrastructure.physics

import android.graphics.PointF
import android.graphics.RectF
import com.crescentflare.slicinggame.infrastructure.geometry.Vector

/**
 * Physics: a solid boundary surrounding the physics engine's space
 */
class PhysicsBoundary(override var x: Float, override var y: Float, var width: Float, var height: Float, var rotation: Float = 0f): PhysicsObject {

    // --
    // Members
    // --

    override var recursiveCheck = 0


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
    // Physics
    // --

    override fun onCollision(hitObject: PhysicsObject?, normal: Vector, timeRemaining: Float, physics: Physics) {
        // No implementation
    }

}
