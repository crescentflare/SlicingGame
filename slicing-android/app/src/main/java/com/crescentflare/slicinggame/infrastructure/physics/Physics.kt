package com.crescentflare.slicinggame.infrastructure.physics

import android.graphics.RectF
import kotlin.math.max
import kotlin.math.min

/**
 * Physics: manages collision and send events to objects
 */
class Physics {

    // --
    // Members
    // --

    var width: Float = 1f
        set(width) {
            field = width
            topBoundary.x = -width
            topBoundary.width = width * 3
            bottomBoundary.x = -width
            bottomBoundary.width = width * 3
            leftBoundary.x = -width
            leftBoundary.width = width
            rightBoundary.x = width
            rightBoundary.width = width
        }

    var height: Float = 1f
        set(height) {
            field = height
            leftBoundary.y = -height
            leftBoundary.height = height * 3
            rightBoundary.y = -height
            rightBoundary.height = height * 3
            topBoundary.y = -height
            topBoundary.height = height
            bottomBoundary.y = height
            bottomBoundary.height = height
        }

    private val objectList = mutableListOf<PhysicsObject>()
    private var leftBoundary = PhysicsBoundary(-1f, -1f, 1f, 3f)
    private var rightBoundary = PhysicsBoundary(1f, -1f, 1f, 3f)
    private var topBoundary = PhysicsBoundary(-1f, -1f, 3f, 1f)
    private var bottomBoundary = PhysicsBoundary(-1f, 1f, 3f, 1f)


    // --
    // Initialization
    // --

    init {
        registerObject(leftBoundary)
        registerObject(rightBoundary)
        registerObject(topBoundary)
        registerObject(bottomBoundary)
    }


    // --
    // Object management
    // --

    fun registerObject(physicsObject: PhysicsObject) {
        if (!objectList.contains(physicsObject)) {
            objectList.add(physicsObject)
        }
    }

    fun clearObjects() {
        objectList.removeAll { it !== leftBoundary && it !== rightBoundary && it !== topBoundary && it !== bottomBoundary }
    }


    // --
    // Movement
    // --

    fun moveObject(movingObject: PhysicsObject, distanceX: Float, distanceY: Float) {
        // Check collision against other objects
        var moveX = distanceX
        var moveY = distanceY
        val bounds = RectF(movingObject.collisionBounds)
        var collisionObject: PhysicsObject? = null
        var collisionSide: CollisionSide? = null
        bounds.offset(movingObject.x, movingObject.y)
        for (checkObject in objectList) {
            if (checkObject !== movingObject) {
                checkObjectCollision(checkObject, moveX, moveY, bounds)?.let {
                    moveX = it.distanceX
                    moveY = it.distanceY
                    collisionObject = checkObject
                    collisionSide = it.side
                }
            }
        }

        // Move
        movingObject.x += moveX
        movingObject.y += moveY

        // Notify objects
        collisionSide?.let { side ->
            collisionObject?.onCollision(movingObject, side.flipped(), this)
            movingObject.onCollision(collisionObject, side, this)
        }
    }


    // --
    // Collision
    // --

    private fun checkObjectCollision(againstObject: PhysicsObject, distanceX: Float, distanceY: Float, bounds: RectF): CollisionResult? {
        // Calculate collision distances for each axis separately
        val objectBounds = againstObject.collisionBounds
        objectBounds.offset(againstObject.x, againstObject.y)
        val entryDistanceX = if (distanceX > 0) objectBounds.left - bounds.right else objectBounds.right - bounds.left
        val entryDistanceY = if (distanceY > 0) objectBounds.top - bounds.bottom else objectBounds.bottom - bounds.top
        val exitDistanceX = if (distanceX > 0) objectBounds.right - bounds.left else objectBounds.left - bounds.right
        val exitDistanceY = if (distanceY > 0) objectBounds.bottom - bounds.top else objectBounds.top - bounds.bottom

        // Calculate collision time relative to the movement distance (ranging from 0 to 1)
        val entryTimeX = if (distanceX == 0f) Float.POSITIVE_INFINITY else entryDistanceX / distanceX
        val entryTimeY = if (distanceY == 0f) Float.POSITIVE_INFINITY else entryDistanceY / distanceY
        val exitTimeX = if (distanceX == 0f) Float.POSITIVE_INFINITY else exitDistanceX / distanceX
        val exitTimeY = if (distanceY == 0f) Float.POSITIVE_INFINITY else exitDistanceY / distanceY

        // Check for collision and return result
        val entryTime = max(entryTimeX, entryTimeY)
        val exitTime = min(exitTimeX, exitTimeY)
        if (entryTime < exitTime && entryTime >= 0 && entryTime <= 1) {
            val side: CollisionSide = if (entryTimeX > entryTimeY) {
                if (distanceX < 0) CollisionSide.Left else CollisionSide.Right
            } else {
                if (distanceY < 0) CollisionSide.Top else CollisionSide.Bottom
            }
            return CollisionResult(distanceX * entryTime, distanceY * entryTime, side)
        }
        return null
    }


    // --
    // Collision side enum
    // --

    enum class CollisionSide {

        Left,
        Right,
        Top,
        Bottom;

        fun flipped(): CollisionSide {
            return when(this) {
                Left -> Right
                Right -> Left
                Top -> Bottom
                Bottom -> Top
            }
        }

    }


    // --
    // Internal collision result class
    // --

    private class CollisionResult(
        val distanceX: Float,
        val distanceY: Float,
        val side: CollisionSide
    )

}
