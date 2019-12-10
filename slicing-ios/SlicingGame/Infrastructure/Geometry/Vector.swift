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

}
