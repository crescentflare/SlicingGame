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

    fun asVectorList(): List<Vector> {
        val result = mutableListOf<Vector>()
        for (index in points.indices) {
            result.add(Vector(points[index], points[(index + 1) % points.size]))
        }
        return result
    }

    fun sliced(vector: Vector): Polygon? {
        // Collect intersections for shape slice entry and exit
        val allVectors = asVectorList()
        val enterVectors = allVectors.filter { it.directionOfPoint(vector.end) > 0 }
        val exitVectors = allVectors.filter { it.directionOfPoint(vector.start) > 0 }
        var enterIntersectVector: Vector? = null
        var enterIntersection: PointF? = null
        var exitIntersectVector: Vector? = null
        var exitIntersection: PointF? = null
        for (checkVector in enterVectors) {
            val intersection = checkVector.intersect(vector)
            if (intersection != null) {
                enterIntersectVector = checkVector
                enterIntersection = intersection
                break
            }
        }
        for (checkVector in exitVectors) {
            val intersection = checkVector.intersect(vector)
            if (intersection != null) {
                exitIntersectVector = checkVector
                exitIntersection = intersection
                break
            }
        }

        // Apply slice
        if (enterIntersectVector != null && exitIntersectVector != null && enterIntersection != null && exitIntersection != null) {
            val slicedPoints = mutableListOf(enterIntersection, exitIntersection)
            var startIndex = allVectors.indexOfFirst { it === exitIntersectVector }
            var endIndex = allVectors.indexOfFirst { it === enterIntersectVector }
            if (startIndex >= 0 && endIndex >= 0) {
                startIndex += 1
                if (exitIntersection == exitIntersectVector.end) {
                    startIndex += 1
                }
                if (enterIntersection == enterIntersectVector.start) {
                    endIndex = (endIndex + allVectors.size - 1) % allVectors.size
                }
                if (endIndex < startIndex) {
                    endIndex += allVectors.size
                }
                for (i in startIndex..endIndex) {
                    slicedPoints.add(points[i % points.size])
                }
                return Polygon(slicedPoints)
            }
        }
        return null
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
