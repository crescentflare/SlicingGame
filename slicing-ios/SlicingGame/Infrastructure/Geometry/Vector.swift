//
//  Polygon.swift
//  Geometry: defines a vector with a start/end position and direction
//

import UIKit

class Vector {

    // --
    // MARK: Members
    // --
    
    var start = CGPoint()
    var end = CGPoint()


    // --
    // MARK: Initialization
    // --
    
    init(start: CGPoint, end: CGPoint) {
        self.start = start
        self.end = end
    }


    // --
    // MARK: Return modified result
    // --
    
    func translated(translateX: CGFloat, translateY: CGFloat) -> Vector {
        return Vector(start: CGPoint(x: start.x + translateX, y: start.y + translateY), end: CGPoint(x: end.x + translateX, y: end.y + translateY))
    }
    
    func scaled(scaleX: CGFloat, scaleY: CGFloat) -> Vector {
        return Vector(start: CGPoint(x: start.x * scaleX, y: start.y * scaleY), end: CGPoint(x: end.x * scaleX, y: end.y * scaleY))
    }

    func reversed() -> Vector {
        return Vector(start: end, end: start)
    }


    // --
    // MARK: Checks
    // --
    
    func isValid() -> Bool {
        return start.x != end.x || start.y != end.y
    }
    
    func directionOf(point: CGPoint) -> CGFloat {
        return (point.y - end.y) * (end.x - start.x) - (end.y - start.y) * (point.x - end.x)
    }
    
    func intersect(withVector: Vector) -> CGPoint? {
        // Intersection direction formula
        let d = (end.x - start.x) * (withVector.end.y - withVector.start.y) - (end.y - start.y) * (withVector.end.x - withVector.start.x)
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
