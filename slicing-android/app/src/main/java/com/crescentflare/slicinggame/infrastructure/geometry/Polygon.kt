package com.crescentflare.slicinggame.infrastructure.geometry

import android.graphics.PointF

/**
 * Geometry: contains a polygon shape
 */
class Polygon {

    // --
    // Members
    // --

    var points = mutableListOf<PointF>()


    // --
    // Initialization
    // --

    constructor()

    constructor(points: List<PointF>) {
        this.points = points.toMutableList()
    }


    // --
    // Apply changes
    // --

    fun clear() {
        points = mutableListOf()
    }

    fun addPoint(point: PointF) {
        points.add(point)
    }


    // --
    // Return modified result
    // --

    fun reversed(): Polygon {
        return Polygon(points.reversed())
    }


    // --
    // Checks
    // --

    fun isValid(): Boolean {
        if (points.size > 2) {
            val middleIndex = mostTopRightIndex()
            val vector = Vector(points[(middleIndex + points.size - 1) % points.size], points[middleIndex])
            return vector.directionOfPoint(points[(middleIndex + 1) % points.size]) != 0f
        }
        return false
    }

    fun isClockwise(): Boolean {
        if (points.size > 2) {
            val middleIndex = mostTopRightIndex()
            val vector = Vector(points[(middleIndex + points.size - 1) % points.size], points[middleIndex])
            return vector.directionOfPoint(points[(middleIndex + 1) % points.size]) > 0
        }
        return false
    }


    // --
    // Helper
    // --

    private fun mostTopRightIndex(): Int {
        var result = 0
        for (index in points.indices) {
            if (index > 0) {
                if (points[index].y < points[result].y || (points[index].y == points[result].y && points[index].x > points[result].x)) {
                    result = index
                }
            }
        }
        return result
    }

}
