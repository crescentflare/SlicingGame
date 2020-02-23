package com.crescentflare.slicinggame.infrastructure.physics

import android.graphics.RectF

/**
 * Physics: manages collision and send events to objects
 */
class Physics {

    // --
    // Members
    // --

    var width: Float = 1f
    var height: Float = 1f
    private val objectList = mutableListOf<PhysicsObject>()


    // --
    // Object management
    // --

    fun registerObject(physicsObject: PhysicsObject) {
        if (!objectList.contains(physicsObject)) {
            objectList.add(physicsObject)
        }
    }

    fun clearObjects() {
        objectList.clear()
    }


    // --
    // Movement
    // --

    fun moveObject(movingObject: PhysicsObject, distanceX: Float, distanceY: Float) {
        // Check collision against other objects
        var moveX = distanceX
        var moveY = distanceY
        val startBounds = RectF(movingObject.collisionBounds)
        var movedBounds = RectF(movingObject.collisionBounds)
        var collisionObject: PhysicsObject? = null
        var collisionSide: CollisionSide? = null
        startBounds.offset(movingObject.x, movingObject.y)
        movedBounds.offset(movingObject.x + moveX, movingObject.y + moveY)
        for (checkObject in objectList) {
            if (checkObject !== movingObject) {
                checkObjectCollision(checkObject, moveX, moveY, startBounds, movedBounds)?.let {
                    moveX = it.distanceX
                    moveY = it.distanceY
                    movedBounds = RectF(movingObject.collisionBounds)
                    movedBounds.offset(movingObject.x + moveX, movingObject.y + moveY)
                    collisionObject = checkObject
                    collisionSide = it.side
                }
            }
        }

        // Check collision against physics boundaries
        if (movedBounds.right > width) {
            moveX = width - startBounds.right
            collisionObject = null
            collisionSide = CollisionSide.Right
        } else if (movedBounds.left < 0) {
            moveX = -startBounds.left
            collisionObject = null
            collisionSide = CollisionSide.Left
        }
        if (movedBounds.bottom > height) {
            moveY = height - startBounds.bottom
            collisionObject = null
            collisionSide = CollisionSide.Bottom
        } else if (movedBounds.top < 0) {
            moveY = -startBounds.top
            collisionObject = null
            collisionSide = CollisionSide.Top
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

    private fun checkObjectCollision(againstObject: PhysicsObject, distanceX: Float, distanceY: Float, startBounds: RectF, endBounds: RectF): CollisionResult? {
        val objectBounds = againstObject.collisionBounds
        objectBounds.offset(againstObject.x, againstObject.y)
        if (endBounds.intersects(objectBounds.left, objectBounds.top, objectBounds.right, objectBounds.bottom)) {
            // Handle collision with horizontal or vertical priority (depending if the start bounds were already intersecting with that axis)
            val preferHorizontalCollision = distanceY == 0f || (distanceY > 0 && startBounds.bottom >= objectBounds.top) || (distanceY < 0 && startBounds.top <= objectBounds.bottom)
            val preferVerticalCollision = distanceX == 0f || (distanceX > 0 && startBounds.right >= objectBounds.left) || (distanceX < 0 && startBounds.left <= objectBounds.right)
            if (preferHorizontalCollision && distanceX != 0f) {
                val side: CollisionSide = if (startBounds.left < endBounds.left) CollisionSide.Right else CollisionSide.Left
                val newDistanceX = if (side == CollisionSide.Right) objectBounds.left - startBounds.right else objectBounds.right - startBounds.left
                return CollisionResult(newDistanceX, newDistanceX / distanceX * distanceY, side)
            } else if (preferVerticalCollision && distanceY != 0f) {
                val side: CollisionSide = if (startBounds.top < endBounds.top) CollisionSide.Bottom else CollisionSide.Top
                val newDistanceY = if (side == CollisionSide.Bottom) objectBounds.top - startBounds.bottom else objectBounds.bottom - startBounds.top
                return CollisionResult(newDistanceY / distanceY * distanceX, newDistanceY, side)
            }

            // Handle remaining cases, collision side depends on the biggest overlap of the intersection
            val horizontalSide: CollisionSide = if (startBounds.left < endBounds.left) CollisionSide.Right else CollisionSide.Left
            val verticalSide: CollisionSide = if (startBounds.top < endBounds.top) CollisionSide.Bottom else CollisionSide.Top
            val intersectionWidth = if (horizontalSide == CollisionSide.Right) endBounds.right - objectBounds.left else objectBounds.right - endBounds.left
            val intersectionHeight = if (verticalSide == CollisionSide.Bottom) endBounds.bottom - objectBounds.top else objectBounds.bottom - endBounds.top
            if (intersectionWidth > intersectionHeight && distanceY != 0f) {
                val newDistanceY = if (verticalSide == CollisionSide.Bottom) objectBounds.top - startBounds.bottom else objectBounds.bottom - startBounds.top
                return CollisionResult(newDistanceY / distanceY * distanceX, newDistanceY, verticalSide)
            } else if (distanceX != 0f) {
                val newDistanceX = if (horizontalSide == CollisionSide.Right) objectBounds.left - startBounds.right else objectBounds.right - startBounds.left
                return CollisionResult(newDistanceX, newDistanceX / distanceX * distanceY, horizontalSide)
            }
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
