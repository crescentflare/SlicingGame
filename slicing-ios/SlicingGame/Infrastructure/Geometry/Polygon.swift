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

}
