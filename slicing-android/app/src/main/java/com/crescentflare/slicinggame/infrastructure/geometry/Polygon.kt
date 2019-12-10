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

}
