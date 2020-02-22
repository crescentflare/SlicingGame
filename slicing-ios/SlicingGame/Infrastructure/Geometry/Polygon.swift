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
    
    func asVectorArray() -> [Vector] {
        var result = [Vector]()
        for index in points.indices {
            result.append(Vector(start: points[index], end: points[(index + 1) % points.count]))
        }
        return result
    }
    
    func asBezierPath(scaleX: CGFloat = 1, scaleY: CGFloat = 1) -> UIBezierPath? {
        if isValid() {
            let path = UIBezierPath()
            for index in points.indices {
                let coordPoint = CGPoint(x: points[index].x * scaleX, y: points[index].y * scaleY)
                if index == 0 {
                    path.move(to: coordPoint)
                } else {
                    path.addLine(to: coordPoint)
                }
            }
            path.close()
            return path
        }
        return nil
    }

    func sliced(vector: Vector) -> Polygon? {
        // Collect intersections for shape slice entry and exit
        let allVectors = asVectorArray()
        let enterVectors = allVectors.filter { $0.directionOf(point: vector.end) > 0 }
        let exitVectors = allVectors.filter { $0.directionOf(point: vector.start) > 0 }
        var enterIntersectVector: Vector?
        var enterIntersection: CGPoint?
        var exitIntersectVector: Vector?
        var exitIntersection: CGPoint?
        for checkVector in enterVectors {
            if let intersection = checkVector.intersect(withVector: vector) {
                enterIntersectVector = checkVector
                enterIntersection = intersection
                break
            }
        }
        for checkVector in exitVectors {
            if let intersection = checkVector.intersect(withVector: vector) {
                exitIntersectVector = checkVector
                exitIntersection = intersection
                break
            }
        }
        
        // Apply slice
        if let enterIntersectVector = enterIntersectVector, let exitIntersectVector = exitIntersectVector, let enterIntersection = enterIntersection, let exitIntersection = exitIntersection {
            var slicedPoints = [enterIntersection, exitIntersection]
            if var startIndex = allVectors.firstIndex(where: { $0 === exitIntersectVector }), var endIndex = allVectors.firstIndex(where: { $0 === enterIntersectVector }) {
                startIndex += 1
                if exitIntersection == exitIntersectVector.end {
                    startIndex += 1
                }
                if enterIntersection == enterIntersectVector.start {
                    endIndex = (endIndex + allVectors.count - 1) % allVectors.count
                }
                if endIndex < startIndex {
                    endIndex += allVectors.count
                }
                for i in startIndex...endIndex {
                    slicedPoints.append(points[i % points.count])
                }
                return Polygon(points: slicedPoints)
            }
        }
        return nil
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
    
    func calculateSurfaceArea() -> CGFloat {
        var first: CGFloat = 0
        var second: CGFloat = 0
        for index in points.indices {
            first += points[index].x * points[(index + 1) % points.count].y
            second += points[index].y * points[(index + 1) % points.count].x
        }
        return (first - second) / 2
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
