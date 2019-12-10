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

}
