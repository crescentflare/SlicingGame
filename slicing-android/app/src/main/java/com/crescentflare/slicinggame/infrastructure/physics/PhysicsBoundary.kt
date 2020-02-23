package com.crescentflare.slicinggame.infrastructure.physics

import android.graphics.RectF

/**
 * Physics: a solid boundary surrounding the physics engine's space
 */
class PhysicsBoundary(override var x: Float, override var y: Float, var width: Float, var height: Float): PhysicsObject {

    // --
    // Properties
    // --

    override val collisionBounds: RectF
        get() = RectF(0f, 0f, width, height)


    // --
    // Physics
    // --

    override fun onCollision(hitObject: PhysicsObject?, side: Physics.CollisionSide, physics: Physics) {
        // No implementation
    }

}
