package com.crescentflare.slicinggame.infrastructure.geometry

import android.graphics.PointF
import kotlin.math.abs
import kotlin.math.sqrt

/**
 * Geometry: defines a vector with a start/end position and direction
 */
class Vector(var start: PointF, var end: PointF) {

    // --
    // Return modified result
    // --

    fun translated(translateX: Float, translateY: Float): Vector {
        return Vector(PointF(start.x + translateX, start.y + translateY), PointF(end.x + translateX, end.y + translateY))
    }

    fun scaled(scaleX: Float, scaleY: Float): Vector {
        return Vector(PointF(start.x * scaleX, start.y * scaleY), PointF(end.x * scaleX, end.y * scaleY))
    }

    fun reversed(): Vector {
        return Vector(end, start)
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
        return sqrt((start.x - end.x) * (start.x - end.x) + (start.y - end.y) * (start.y - end.y))
    }

    fun directionOfPoint(point: PointF): Float {
        return (point.y - end.y) * (end.x - start.x) - (end.y - start.y) * (point.x - end.x)
    }

    fun intersect(otherVector: Vector): PointF? {
        // Intersection direction formula
        val d = (end.x - start.x) * (otherVector.end.y - otherVector.start.y) - (end.y - start.y) * (otherVector.end.x - otherVector.start.x)
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

}
