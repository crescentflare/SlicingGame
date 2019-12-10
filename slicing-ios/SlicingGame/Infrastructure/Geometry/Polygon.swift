//
//  Polygon.swift
//  Geometry: contains a polygon shape
//

import UIKit

class Polygon {

    // --
    // MARK: Members
    // --
    
    var points = [CGPoint]()


    // --
    // MARK: Initialization
    // --
    
    init() {
    }
    
    init(points: [CGPoint]) {
        self.points = points
    }


    // --
    // MARK: Apply changes
    // --
    
    func clear() {
        points = []
    }
    
    func addPoint(_ point: CGPoint) {
        points.append(point)
    }
    

    // --
    // MARK: Return modified result
    // --

    func reversed() -> Polygon {
        return Polygon(points: points.reversed())
    }


    // --
    // MARK: Checks
    // --
    
    func isValid() -> Bool {
        if points.count > 2 {
            let middleIndex = mostTopRightIndex()
            let vector = Vector(start: points[(middleIndex + points.count - 1) % points.count], end: points[middleIndex])
            return vector.directionOf(point: points[(middleIndex + 1) % points.count]) != 0
        }
        return false
    }
    
    func isClockwise() -> Bool {
        if points.count > 2 {
            let middleIndex = mostTopRightIndex()
            let vector = Vector(start: points[(middleIndex + points.count - 1) % points.count], end: points[middleIndex])
            return vector.directionOf(point: points[(middleIndex + 1) % points.count]) > 0
        }
        return false
    }
    
    
    // --
    // MARK: Helper
    // --
    
    private func mostTopRightIndex() -> Int {
        var result = 0
        for index in points.indices {
            if index > 0 {
                if points[index].y < points[result].y || (points[index].y == points[result].y && points[index].x > points[result].x) {
                    result = index
                }
            }
        }
        return result
    }

}
