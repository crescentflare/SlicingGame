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

}
