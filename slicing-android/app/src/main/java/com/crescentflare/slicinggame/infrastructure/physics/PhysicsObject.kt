package com.crescentflare.slicinggame.infrastructure.physics

import android.graphics.PointF
import android.graphics.RectF
import com.crescentflare.slicinggame.infrastructure.geometry.Vector

/**
 * Physics: an object in the physics engine
 */
interface PhysicsObject {

    var x: Float
    var y: Float
    var lethal: Boolean
    var recursiveCheck: Int
    val collisionBounds: RectF
    val collisionRotation: Float
    val collisionPivot: PointF

    fun onCollision(hitObject: PhysicsObject?, normal: Vector, timeRemaining: Float, physics: Physics)

}
