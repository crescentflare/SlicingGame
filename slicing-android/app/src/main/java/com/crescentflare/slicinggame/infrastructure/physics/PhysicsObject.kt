package com.crescentflare.slicinggame.infrastructure.physics

import android.graphics.RectF

/**
 * Physics: an object in the physics engine
 */
interface PhysicsObject {

    var x: Float
    var y: Float
    val collisionBounds: RectF

    fun onCollision(hitObject: PhysicsObject?, side: Physics.CollisionSide, physics: Physics)

}
