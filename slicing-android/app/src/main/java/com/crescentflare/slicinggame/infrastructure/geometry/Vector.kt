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

}
