package com.crescentflare.slicinggame.infrastructure.physics

import android.graphics.PointF
import android.graphics.RectF
import com.crescentflare.slicinggame.infrastructure.geometry.Polygon
import com.crescentflare.slicinggame.infrastructure.geometry.Vector
import java.lang.ref.WeakReference
import kotlin.math.abs
import kotlin.math.max
import kotlin.math.min

/**
 * Physics: manages collision and send events to objects
 */
class Physics {

    // --
    // Physics listener
    // --

    interface Listener {

        fun onLethalCollision()

    }


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

    var listener: Listener?
        get() = listenerReference?.get()
        set(listener) {
            listenerReference = if (listener != null) {
                WeakReference(listener)
            } else {
                null
            }
        }

    private val objectList = mutableListOf<PhysicsObject>()
    private var leftBoundary = PhysicsBoundary(-1f, -1f, 1f, 3f)
    private var rightBoundary = PhysicsBoundary(1f, -1f, 1f, 3f)
    private var topBoundary = PhysicsBoundary(-1f, -1f, 3f, 1f)
    private var bottomBoundary = PhysicsBoundary(-1f, 1f, 3f, 1f)
    private var listenerReference: WeakReference<Listener>? = null


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

    fun unregisterObject(physicsObject: PhysicsObject) {
        objectList.remove(physicsObject)
    }

    fun clearObjects() {
        objectList.removeAll { it !== leftBoundary && it !== rightBoundary && it !== topBoundary && it !== bottomBoundary }
    }

    fun prepareObjects() {
        objectList.forEach {
            it.recursiveCheck = 0
        }
    }


    // --
    // Movement
    // --

    fun moveObject(movingObject: PhysicsObject, distanceX: Float, distanceY: Float, timeInterval: Float) {
        // Check collision against other objects
        var moveX = distanceX
        var moveY = distanceY
        val bounds = RectF(movingObject.collisionBounds)
        var collisionObject: PhysicsObject? = null
        var collisionNormal: Vector? = null
        bounds.offset(movingObject.x, movingObject.y)
        for (checkObject in objectList) {
            if (checkObject !== movingObject) {
                val collision: CollisionResult?
                if (movingObject.collisionRotation == 0f && checkObject.collisionRotation == 0f) {
                    collision = checkSimpleCollision(checkObject, moveX, moveY, bounds)
                } else {
                    collision = checkRotatedCollision(movingObject, checkObject, moveX, moveY)
                }
                collision?.let {
                    moveX = it.distanceX
                    moveY = it.distanceY
                    collisionObject = checkObject
                    collisionNormal = it.normal
                }
            }
        }

        // Move
        movingObject.x += moveX
        movingObject.y += moveY

        // Notify objects
        collisionNormal?.let { normal ->
            var timeRemaining = 1f - if (distanceX > distanceY) abs(moveX) / abs(distanceX) else abs(moveY) / abs(distanceY)
            if (timeRemaining == 1f || (moveX < 0.000001 && moveY < 0.000001)) {
                movingObject.recursiveCheck++
                if (movingObject.recursiveCheck >= 4) {
                    timeRemaining = 0f
                }
            } else {
                movingObject.recursiveCheck = 0
            }
            collisionObject?.onCollision(movingObject, normal.reversed().unit(), 0f, this)
            movingObject.onCollision(collisionObject, normal, timeRemaining * timeInterval, this)
        }

        // Notify listener if needed
        if (movingObject.lethal || collisionObject?.lethal == true) {
            listener?.onLethalCollision()
        }
    }


    // --
    // Collision
    // --

    private fun checkSimpleCollision(againstObject: PhysicsObject, distanceX: Float, distanceY: Float, bounds: RectF): CollisionResult? {
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
        var entryTime = max(entryTimeX, entryTimeY)
        val exitTime = min(exitTimeX, exitTimeY)
        if (entryTime < 0 && abs(entryTime * distanceX) < 0.0001 && abs(entryTime * distanceY) < 0.0001) {
            entryTime = 0f
        }
        if (entryTime < exitTime && entryTime >= 0 && entryTime <= 1) {
            val normal: Vector = if (entryTimeX > entryTimeY) {
                Vector(if (distanceX < 0) 1f else -1f, 0f)
            } else {
                Vector(0f, if (distanceY < 0) 1f else -1f)
            }
            return CollisionResult(distanceX * entryTime, distanceY * entryTime, normal)
        }
        return null
    }

    private fun checkRotatedCollision(movingObject: PhysicsObject, targetObject: PhysicsObject, distanceX: Float, distanceY: Float): CollisionResult? {
        // Create collision polygon and cast vector
        val collisionPolygon = createCollisionPolygon(movingObject, targetObject)
        val collisionLines = collisionPolygon.asVectorList()
        val castPoint = PointF(movingObject.x - targetObject.x, movingObject.y - targetObject.y)
        val castVector = Vector(PointF(castPoint.x - distanceX, castPoint. y - distanceY), PointF(castPoint.x + distanceX, castPoint.y + distanceY))

        // Determine time of collision
        var entryTime = Float.POSITIVE_INFINITY
        var hitLineIndex = -1
        for (line in collisionLines.withIndex()) {
            if (line.value.directionOfPoint(castVector.start) <= 0 && line.value.directionOfPoint(castVector.end) >= 0) {
                castVector.intersect(line.value)?.let { intersection ->
                    val intersectDistanceX = intersection.x - castPoint.x
                    val intersectDistanceY = intersection.y - castPoint.y
                    val checkEntryTime: Float
                    if (abs(intersectDistanceX) > abs(intersectDistanceY)) {
                        checkEntryTime = if (distanceX != 0f) intersectDistanceX / distanceX else Float.POSITIVE_INFINITY
                    } else {
                        checkEntryTime = if (distanceY != 0f) intersectDistanceY / distanceY else Float.POSITIVE_INFINITY
                    }
                    if (checkEntryTime < entryTime) {
                        entryTime = checkEntryTime
                        hitLineIndex = line.index
                    }
                    entryTime = min(entryTime, checkEntryTime)
                }
            }
        }

        // Check collision time and return result
        if (entryTime < 0 && abs(entryTime * distanceX) < 0.0001 && abs(entryTime * distanceY) < 0.0001) {
            entryTime = 0f
        }
        if (entryTime >= 0 && entryTime <= 1 && hitLineIndex >= 0) {
            return CollisionResult(distanceX * entryTime, distanceY * entryTime, collisionLines[hitLineIndex].perpendicular().unit())
        }
        return null
    }

    private fun createCollisionPolygon(movingObject: PhysicsObject, targetObject: PhysicsObject): Polygon {
        // Create polygons of rotated square shapes
        val movingObjectPolygon = Polygon(movingObject.collisionBounds, movingObject.collisionPivot, movingObject.collisionRotation)
        val targetObjectPolygon = Polygon(targetObject.collisionBounds, targetObject.collisionPivot, targetObject.collisionRotation)
        var movingObjectIndex = (movingObjectPolygon.mostTopRightIndex() + 2) % 4
        var targetObjectIndex = targetObjectPolygon.mostTopRightIndex()

        // Determine how to follow the shape when overlapping the polygon on the target polygon's points
        val movingObjectDistanceX = movingObjectPolygon.points[movingObjectIndex].x - movingObjectPolygon.points[(movingObjectIndex + 1) % 4].x
        val movingObjectDistanceY = movingObjectPolygon.points[movingObjectIndex].y - movingObjectPolygon.points[(movingObjectIndex + 1) % 4].y
        val targetObjectDistanceX = targetObjectPolygon.points[(targetObjectIndex + 1) % 4].x - targetObjectPolygon.points[targetObjectIndex].x
        val targetObjectDistanceY = targetObjectPolygon.points[(targetObjectIndex + 1) % 4].y - targetObjectPolygon.points[targetObjectIndex].y
        val movingObjectSlope = if (movingObjectDistanceY != 0f) movingObjectDistanceX / movingObjectDistanceY else Float.POSITIVE_INFINITY
        val targetObjectSlope = if (targetObjectDistanceY != 0f) targetObjectDistanceX / targetObjectDistanceY else Float.POSITIVE_INFINITY
        if (movingObjectSlope > targetObjectSlope) {
            movingObjectIndex = (movingObjectIndex + 1) % 4
        }

        // Overlap object polygon on the points of the target polygon and trace their edges
        val result = Polygon()
        for (i in 0 until 8) {
            val x = targetObjectPolygon.points[targetObjectIndex].x - movingObjectPolygon.points[movingObjectIndex].x
            val y = targetObjectPolygon.points[targetObjectIndex].y - movingObjectPolygon.points[movingObjectIndex].y
            result.addPoint(PointF(x, y))
            if (i % 2 == 0) {
                targetObjectIndex = (targetObjectIndex + 1) % 4
            } else {
                movingObjectIndex = (movingObjectIndex + 1) % 4
            }
        }
        return result
    }


    // --
    // Internal collision result class
    // --

    private class CollisionResult(
        val distanceX: Float,
        val distanceY: Float,
        val normal: Vector
    )

}
