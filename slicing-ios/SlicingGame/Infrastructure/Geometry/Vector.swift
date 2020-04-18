//
//  Polygon.swift
//  Geometry: defines a vector with a start/end position and direction
//

import UIKit

class Vector {

    // --
    // MARK: Members
    // --
    
    var x: CGFloat {
        set {
            end.x = start.x + newValue
        }
        get { return end.x - start.x }
    }

    var y: CGFloat {
        set {
            end.y = start.y + newValue
        }
        get { return end.y - start.y }
    }

    var start = CGPoint()
    var end = CGPoint()


    // --
    // MARK: Initialization
    // --
    
    convenience init(x: CGFloat, y: CGFloat) {
        self.init(start: CGPoint.zero, end: CGPoint(x: x, y: y))
    }
    
    init(start: CGPoint, end: CGPoint) {
        self.start = start
        self.end = end
    }

    init(directionAngle: CGFloat, pivot: CGPoint? = nil) {
        self.start = pivot ?? CGPoint.zero
        self.end = CGPoint(x: start.x + sin(directionAngle * CGFloat.pi * 2 / 360), y: start.y - cos(directionAngle * CGFloat.pi * 2 / 360))
    }

    
    // --
    // MARK: Operators
    // --

    static func *(vector: Vector, multiplier: CGFloat) -> Vector {
        return Vector(start: vector.start, end: CGPoint(x: vector.start.x + vector.x * multiplier, y: vector.start.y + vector.y * multiplier))
    }
    
    static func *=(vector: Vector, multiplier: CGFloat) {
        vector.x *= multiplier
        vector.y *= multiplier
    }
    

    // --
    // MARK: Return modified result
    // --
    
    func unit() -> Vector {
        let magnitude = distance()
        return Vector(x: x / magnitude, y: y / magnitude)
    }
    
    func translated(translateX: CGFloat, translateY: CGFloat) -> Vector {
        return Vector(start: CGPoint(x: start.x + translateX, y: start.y + translateY), end: CGPoint(x: end.x + translateX, y: end.y + translateY))
    }
    
    func scaled(scaleX: CGFloat, scaleY: CGFloat) -> Vector {
        return Vector(start: CGPoint(x: start.x * scaleX, y: start.y * scaleY), end: CGPoint(x: end.x * scaleX, y: end.y * scaleY))
    }

    func reversed() -> Vector {
        return Vector(start: end, end: start)
    }
    
    func perpendicular() -> Vector {
        return Vector(start: start, end: CGPoint(x: start.x + y, y: start.y - x))
    }

    func stretchedToEdges(topLeft: CGPoint, bottomRight: CGPoint) -> Vector {
        var newStart = start
        var newEnd = end
        if (abs(start.x - end.x) > abs(start.y - end.y)) {
            let slope = (start.y - end.y) / (start.x - end.x)
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
            let slope = (start.x - end.x) / (start.y - end.y)
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
        return Vector(start: newStart, end: newEnd)
    }

    
    // --
    // MARK: Checks
    // --
    
    func isValid() -> Bool {
        return start.x != end.x || start.y != end.y
    }
    
    func distance() -> CGFloat {
        return sqrt(x * x + y * y)
    }

    func directionOf(point: CGPoint) -> CGFloat {
        return (point.y - end.y) * (end.x - start.x) - (end.y - start.y) * (point.x - end.x)
    }
    
    func intersect(withVector: Vector) -> CGPoint? {
        // Intersection direction formula
        let d = x * withVector.y - y * withVector.x
        if d == 0 {
            return nil
        }
        
        // Distance formulas
        let u = ((withVector.start.x - start.x) * (withVector.end.y - withVector.start.y) - (withVector.start.y - start.y) * (withVector.end.x - withVector.start.x)) / d
        let v = ((withVector.start.x - start.x) * (end.y - start.y) - (withVector.start.y - start.y) * (end.x - start.x)) / d
        if u < 0 || u > 1 {
            return nil
        }
        if v < 0 || v > 1 {
            return nil
        }
        
        // Return the intersection result
        return CGPoint(x: start.x + u * (end.x - start.x), y: start.y + u * (end.y - start.y))
    }
    
    func intersect(withRect: CGRect) -> CGPoint? {
        // Return early if the starting point is already inside the rectangle
        if withRect.contains(start) {
            return CGPoint(x: start.x, y: start.y)
        }
        
        // Calculate intersection distances for each axis separately
        let entryDistanceX = x > 0 ? withRect.minX - start.x : withRect.maxX - start.x
        let entryDistanceY = y > 0 ? withRect.minY - start.y : withRect.maxY - start.y
        let exitDistanceX = x > 0 ? withRect.maxX - start.x : withRect.minX - start.x
        let exitDistanceY = y > 0 ? withRect.maxY - start.y : withRect.minY - start.y
        
        // Calculate intersection time relative to the vector length (ranging from 0 to 1)
        let entryTimeX = x == 0 ? CGFloat.infinity : entryDistanceX / x
        let entryTimeY = y == 0 ? CGFloat.infinity : entryDistanceY / y
        let exitTimeX = x == 0 ? CGFloat.infinity : exitDistanceX / x
        let exitTimeY = y == 0 ? CGFloat.infinity : exitDistanceY / y
        
        // Check for intersection and return result
        let entryTime = max(entryTimeX, entryTimeY)
        let exitTime = min(exitTimeX, exitTimeY)
        if entryTime < exitTime && entryTime >= 0 && entryTime <= 1 {
            return CGPoint(x: start.x + x * entryTime, y: start.y + y * entryTime)
        }
        return nil
    }
    
    func intersect(withPolygon: Polygon) -> CGPoint? {
        // Return early if the starting point is already inside the polygon
        if withPolygon.contains(start) {
            return CGPoint(x: start.x, y: start.y)
        }
        
        // Check if intersecting with the polygon lines
        var closestIntersection: CGPoint?
        for vector in withPolygon.asVectorArray() {
            if vector.directionOf(point: start) < 0 && vector.directionOf(point: end) > 0 {
                if let intersection = vector.intersect(withVector: self) {
                    if let previousIntersection = closestIntersection {
                        if abs(intersection.x - vector.start.x) < abs(previousIntersection.x - vector.start.x) && abs(intersection.y - vector.start.y) < abs(previousIntersection.y - vector.start.y) {
                            closestIntersection = intersection
                        }
                    } else {
                        closestIntersection = intersection
                    }
                }
            }
        }
        return closestIntersection
    }
    
    func edgeIntersections(withPolygon: Polygon) -> [CGPoint] {
        var points = [CGPoint]()
        for vector in withPolygon.asVectorArray() {
            if let point = intersect(withVector: vector) {
                points.append(point)
            }
        }
        return points
    }

}
