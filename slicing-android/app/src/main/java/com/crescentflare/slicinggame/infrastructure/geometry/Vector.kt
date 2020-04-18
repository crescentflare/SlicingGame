package com.crescentflare.slicinggame.infrastructure.geometry

import android.graphics.PointF
import android.graphics.RectF
import kotlin.math.*

/**
 * Geometry: defines a vector with a start/end position and direction
 */
class Vector {

    // --
    // Members
    // --

    var x: Float
        get() = end.x - start.x
        set(x) {
            end.x = start.x + x
        }

    var y: Float
        get() = end.y - start.y
        set(y) {
            end.y = start.y + y
        }

    var start: PointF
    var end: PointF


    // --
    // Initialization
    // --

    constructor(x: Float, y: Float): this(PointF(), PointF(x, y))

    constructor(start: PointF, end: PointF) {
        this.start = start
        this.end = end
    }

    constructor(directionAngle: Float, pivot: PointF? = null) {
        this.start = pivot ?: PointF()
        this.end = PointF(sin(start.x + directionAngle * PI.toFloat() * 2 / 360), start.y - cos(directionAngle * PI.toFloat() * 2 / 360))
    }


    // --
    // Operators
    // --

    operator fun times(multiplier: Float): Vector {
        return Vector(PointF(start.x, start.y), PointF(start.x + x * multiplier, start.y + y * multiplier))
    }

    operator fun timesAssign(multiplier: Float) {
        x *= multiplier
        y *= multiplier
    }


    // --
    // Return modified result
    // --

    fun unit(): Vector {
        val magnitude = distance()
        return Vector(x / magnitude, y / magnitude)
    }

    fun translated(translateX: Float, translateY: Float): Vector {
        return Vector(PointF(start.x + translateX, start.y + translateY), PointF(end.x + translateX, end.y + translateY))
    }

    fun scaled(scaleX: Float, scaleY: Float): Vector {
        return Vector(PointF(start.x * scaleX, start.y * scaleY), PointF(end.x * scaleX, end.y * scaleY))
    }

    fun reversed(): Vector {
        return Vector(end, start)
    }

    fun perpendicular(): Vector {
        return Vector(PointF(start.x, start.y), PointF(start.x + y, start.y - x))
    }

    fun stretchedToEdges(topLeft: PointF, bottomRight: PointF): Vector {
        val newStart = PointF(start.x, start.y)
        val newEnd = PointF(end.x, end.y)
        if (abs(start.x - end.x) > abs(start.y - end.y)) {
            val slope = (start.y - end.y) / (start.x - end.x)
            if (start.x < end.x) {
                newStart.x = topLeft.x
                newStart.y += (topLeft.x - start.x) * slope
                newEnd.x = bottomRight.x
                newEnd.y += (bottomRight.x - end.x) * slope
            } else {
                newStart.x = bottomRight.x
                newStart.y += (bottomRight.x - start.x) * slope
                newEnd.x = topLeft.x
                newEnd.y += (topLeft.x - end.x) * slope
            }
        } else {
            val slope = (start.x - end.x) / (start.y - end.y)
            if (start.y < end.y) {
                newStart.x += (topLeft.y - start.y) * slope
                newStart.y = topLeft.y
                newEnd.x += (bottomRight.y - end.y) * slope
                newEnd.y = bottomRight.y
            } else {
                newStart.x += (bottomRight.y - start.y) * slope
                newStart.y = bottomRight.y
                newEnd.x += (topLeft.y - end.y) * slope
                newEnd.y = topLeft.y
            }
        }
        return Vector(newStart, newEnd)
    }


    // --
    // Checks
    // --

    fun isValid(): Boolean {
        return start.x != end.x || start.y != end.y
    }

    fun distance(): Float {
        return sqrt(x * x + y * y)
    }

    fun directionOfPoint(point: PointF): Float {
        return (point.y - end.y) * (end.x - start.x) - (end.y - start.y) * (point.x - end.x)
    }

    fun intersect(otherVector: Vector): PointF? {
        // Intersection direction formula
        val d = x * otherVector.y - y * otherVector.x
        if (d == 0f) {
            return null
        }

        // Distance formulas
        val u = ((otherVector.start.x - start.x) * (otherVector.end.y - otherVector.start.y) - (otherVector.start.y - start.y) * (otherVector.end.x - otherVector.start.x)) / d
        val v = ((otherVector.start.x - start.x) * (end.y - start.y) - (otherVector.start.y - start.y) * (end.x - start.x)) / d
        if (u < 0 || u > 1) {
            return null
        }
        if (v < 0 || v > 1) {
            return null
        }

        // Return the intersection result
        return PointF(start.x + u * (end.x - start.x), start.y + u * (end.y - start.y))
    }

    fun intersect(rect: RectF): PointF? {
        // Return early if the starting point is already inside the rectangle
        if (rect.contains(start.x, start.y)) {
            return PointF(start.x, start.y)
        }

        // Calculate intersection distances for each axis separately
        val entryDistanceX = if (x > 0) rect.left - start.x else rect.right - start.x
        val entryDistanceY = if (y > 0) rect.top - start.y else rect.bottom - start.y
        val exitDistanceX = if (x > 0) rect.right - start.x else rect.left - start.x
        val exitDistanceY = if (y > 0) rect.bottom - start.y else rect.top - start.y

        // Calculate intersection time relative to the vector length (ranging from 0 to 1)
        val entryTimeX = if (x == 0f) Float.POSITIVE_INFINITY else entryDistanceX / x
        val entryTimeY = if (y == 0f) Float.POSITIVE_INFINITY else entryDistanceY / y
        val exitTimeX = if (x == 0f) Float.POSITIVE_INFINITY else exitDistanceX / x
        val exitTimeY = if (y == 0f) Float.POSITIVE_INFINITY else exitDistanceY / y

        // Check for intersection and return result
        val entryTime = max(entryTimeX, entryTimeY)
        val exitTime = min(exitTimeX, exitTimeY)
        if (entryTime < exitTime && entryTime >= 0 && entryTime <= 1) {
            return PointF(start.x + x * entryTime, start.y + y * entryTime)
        }
        return null
    }

    fun intersect(polygon: Polygon): PointF? {
        // Return early if the starting point is already inside the polygon
        if (polygon.contains(start)) {
            return PointF(start.x, start.y)
        }

        // Check if intersecting with the polygon lines
        var closestIntersection: PointF? = null
        for (vector in polygon.asVectorList()) {
            if (vector.directionOfPoint(start) < 0 && vector.directionOfPoint(end) > 0) {
                vector.intersect(this)?.let {
                    val previousIntersection = closestIntersection
                    if (previousIntersection != null) {
                        if (abs(it.x - vector.start.x) < abs(previousIntersection.x - vector.start.x) && abs(it.y - vector.start.y) < abs(previousIntersection.y - vector.start.y)) {
                            closestIntersection = it
                        }
                    } else {
                        closestIntersection = it
                    }
                }
            }
        }
        return closestIntersection
    }

    fun edgeIntersections(polygon: Polygon): List<PointF> {
        val points = mutableListOf<PointF>()
        for (vector in polygon.asVectorList()) {
            intersect(vector)?.let {
                points.add(it)
            }
        }
        return points
    }

}
