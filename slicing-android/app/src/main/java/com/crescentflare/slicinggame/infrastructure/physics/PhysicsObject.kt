package com.crescentflare.slicinggame.infrastructure.physics

import android.graphics.PointF
import android.graphics.RectF

/**
 * Physics: an object in the physics engine
 */
interface PhysicsObject {

    var x: Float
    var y: Float
    var recursiveCheck: Int
    val collisionBounds: RectF
    val collisionRotation: Float
    val collisionPivot: PointF

    fun onCollision(hitObject: PhysicsObject?, side: Physics.CollisionSide, timeRemaining: Float, physics: Physics)

}
