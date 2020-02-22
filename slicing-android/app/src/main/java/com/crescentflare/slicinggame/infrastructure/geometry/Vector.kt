package com.crescentflare.slicinggame.infrastructure.geometry

import android.graphics.PointF

/**
 * Geometry: defines a vector with a start/end position and direction
 */
class Vector(var start: PointF, var end: PointF) {

    // --
    // Return modified result
    // --

    fun reversed(): Vector {
        return Vector(end, start)
    }


    // --
    // Checks
    // --

    fun isValid(): Boolean {
        return start.x != end.x || start.y != end.y
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
