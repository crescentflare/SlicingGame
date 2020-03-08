//
//  Physics.swift
//  Physics: manages collision and send events to objects
//

import UIKit

protocol PhysicsDelegate: class {
    
    func didLethalCollision()
    
}

class Physics {

    // --
    // MARK: Members
    // --
    
    var width: Float = 1 {
        didSet {
            topBoundary.x = -width
            topBoundary.width = width * 3
            bottomBoundary.x = -width
            bottomBoundary.width = width * 3
            leftBoundary.x = -width
            leftBoundary.width = width
            rightBoundary.x = width
            rightBoundary.width = width
        }
    }
    
    var height: Float = 1 {
        didSet {
            leftBoundary.y = -height
            leftBoundary.height = height * 3
            rightBoundary.y = -height
            rightBoundary.height = height * 3
            topBoundary.y = -height
            topBoundary.height = height
            bottomBoundary.y = height
            bottomBoundary.height = height
        }
    }
    
    weak var delegate: PhysicsDelegate?
    private var objects = [PhysicsObject]()
    private var leftBoundary = PhysicsBoundary(x: -1, y: -1, width: 1, height: 3)
    private var rightBoundary = PhysicsBoundary(x: 1, y: -1, width: 1, height: 3)
    private var topBoundary = PhysicsBoundary(x: -1, y: -1, width: 3, height: 1)
    private var bottomBoundary = PhysicsBoundary(x: -1, y: 1, width: 3, height: 1)


    // --
    // MARK: Initialization
    // --

    init() {
        registerObject(leftBoundary)
        registerObject(rightBoundary)
        registerObject(topBoundary)
        registerObject(bottomBoundary)
    }
    

    // --
    // MARK: Object management
    // --
    
    func registerObject(_ object: PhysicsObject) {
        if !objects.contains { $0 === object } {
            objects.append(object)
        }
    }
    
    func unregisterObject(_ object: PhysicsObject) {
        if let index = objects.firstIndex(where: { $0 === object }) {
            objects.remove(at: index)
        }
    }

    func clearObjects() {
        objects.removeAll { $0 !== leftBoundary && $0 !== rightBoundary && $0 !== topBoundary && $0 !== bottomBoundary }
    }
    
    func prepareObjects() {
        objects.forEach {
            $0.recursiveCheck = 0
        }
    }
    

    // --
    // MARK: Movement
    // --
    
    func moveObject(_ object: PhysicsObject, distanceX: Float, distanceY: Float, timeInterval: TimeInterval) {
        // Check collision against other objects
        var moveX = distanceX
        var moveY = distanceY
        let bounds = object.collisionBounds.offsetBy(dx: CGFloat(object.x), dy: CGFloat(object.y))
        var collisionObject: PhysicsObject?
        var collisionNormal: Vector?
        for checkObject in objects {
            if checkObject !== object {
                let collision: CollisionResult?
                if object.collisionRotation == 0 && checkObject.collisionRotation == 0 {
                    collision = checkSimpleCollision(object: checkObject, distanceX: moveX, distanceY: moveY, bounds: bounds)
                } else {
                    collision = checkRotatedCollision(object: object, targetObject: checkObject, distanceX: moveX, distanceY: moveY)
                }
                if let collision = collision {
                    moveX = collision.distanceX
                    moveY = collision.distanceY
                    collisionObject = checkObject
                    collisionNormal = collision.normal
                }
            }
        }
        
        // Move
        object.x += moveX
        object.y += moveY
        
        // Notify objects
        if let collisionNormal = collisionNormal {
            var timeRemaining = TimeInterval(1 - (distanceX > distanceY ? abs(moveX) / abs(distanceX) : abs(moveY) / abs(distanceY)))
            if timeRemaining == 1 || (moveX < 0.000001 && moveY < 0.000001) {
                object.recursiveCheck += 1
                if object.recursiveCheck >= 4 {
                    timeRemaining = 0
                }
            } else {
                object.recursiveCheck = 0
            }
            collisionObject?.didCollide(withObject: object, normal: collisionNormal.reversed().unit(), timeRemaining: 0, physics: self)
            object.didCollide(withObject: collisionObject, normal: collisionNormal, timeRemaining: timeRemaining * timeInterval, physics: self)
        }
        
        // Notify delegate if needed
        if object.lethal || collisionObject?.lethal ?? false {
            delegate?.didLethalCollision()
        }
    }
    

    // --
    // MARK: Collision
    // --
    
    func intersectsSprite(vector: Vector) -> Bool {
        for object in objects {
            if object is Sprite {
                let spriteBounds = object.collisionBounds.offsetBy(dx: CGFloat(object.x), dy: CGFloat(object.y))
                if object.collisionRotation == 0 {
                    if vector.intersect(withRect: spriteBounds) != nil {
                        return true
                    }
                } else {
                    let polygon = Polygon(rect: spriteBounds, pivot: CGPoint(x: object.collisionPivot.x + CGFloat(object.x), y: object.collisionPivot.y + CGFloat(object.y)), rotation: CGFloat(object.collisionRotation))
                    if vector.intersect(withPolygon: polygon) != nil {
                        return true
                    }
                }
            }
        }
        return false
    }
    
    func intersectsSprite(polygon: Polygon) -> Bool {
        for object in objects {
            if object is Sprite {
                let spritePolygon = Polygon(rect: object.collisionBounds.offsetBy(dx: CGFloat(object.x), dy: CGFloat(object.y)), pivot: CGPoint(x: object.collisionPivot.x + CGFloat(object.x), y: object.collisionPivot.y + CGFloat(object.y)), rotation: CGFloat(object.collisionRotation))
                if (polygon.intersect(withPolygon: spritePolygon)) {
                    return true
                }
            }
        }
        return false
    }

    private func checkSimpleCollision(object: PhysicsObject, distanceX: Float, distanceY: Float, bounds: CGRect) -> CollisionResult? {
        // Calculate collision distances for each axis separately
        let objectBounds = object.collisionBounds.offsetBy(dx: CGFloat(object.x), dy: CGFloat(object.y))
        let entryDistanceX = distanceX > 0 ? Float(objectBounds.minX - bounds.maxX) : Float(objectBounds.maxX - bounds.minX)
        let entryDistanceY = distanceY > 0 ? Float(objectBounds.minY - bounds.maxY) : Float(objectBounds.maxY - bounds.minY)
        let exitDistanceX = distanceX > 0 ? Float(objectBounds.maxX - bounds.minX) : Float(objectBounds.minX - bounds.maxX)
        let exitDistanceY = distanceY > 0 ? Float(objectBounds.maxY - bounds.minY) : Float(objectBounds.minY - bounds.maxY)
        
        // Calculate collision time relative to the movement distance (ranging from 0 to 1)
        let entryTimeX = distanceX == 0 ? Float.infinity : entryDistanceX / distanceX
        let entryTimeY = distanceY == 0 ? Float.infinity : entryDistanceY / distanceY
        let exitTimeX = distanceX == 0 ? Float.infinity : exitDistanceX / distanceX
        let exitTimeY = distanceY == 0 ? Float.infinity : exitDistanceY / distanceY
        
        // Check for collision and return result
        var entryTime = max(entryTimeX, entryTimeY)
        let exitTime = min(exitTimeX, exitTimeY)
        if entryTime < 0 && abs(entryTime * distanceX) < 0.0001 && abs(entryTime * distanceY) < 0.0001 {
            entryTime = 0
        }
        if entryTime < exitTime && entryTime >= 0 && entryTime <= 1 {
            let normal: Vector
            if entryTimeX > entryTimeY {
                normal = Vector(x: distanceX < 0 ? 1 : -1, y: 0)
            } else {
                normal = Vector(x: 0, y: distanceY < 0 ? 1 : -1)
            }
            return CollisionResult(distanceX: distanceX * entryTime, distanceY: distanceY * entryTime, normal: normal)
        }
        return nil
    }
    
    private func checkRotatedCollision(object: PhysicsObject, targetObject: PhysicsObject, distanceX: Float, distanceY: Float) -> CollisionResult? {
        // Create collision polygon and cast vector
        let collisionPolygon = createCollisionPolygon(object: object, targetObject: targetObject)
        let collisionLines = collisionPolygon.asVectorArray()
        let castPoint = CGPoint(x: CGFloat(object.x - targetObject.x), y: CGFloat(object.y - targetObject.y))
        let castVector = Vector(start: CGPoint(x: castPoint.x - CGFloat(distanceX), y: castPoint.y - CGFloat(distanceY)), end: CGPoint(x: castPoint.x + CGFloat(distanceX), y: castPoint.y + CGFloat(distanceY)))
        
        // Determine time of collision
        var entryTime = Float.infinity
        var hitLineIndex = -1
        for (index, line) in collisionLines.enumerated() {
            if line.directionOf(point: castVector.start) <= 0 && line.directionOf(point: castVector.end) >= 0 {
                if let intersection = castVector.intersect(withVector: line) {
                    let intersectDistanceX = intersection.x - castPoint.x
                    let intersectDistanceY = intersection.y - castPoint.y
                    let checkEntryTime: Float
                    if abs(intersectDistanceX) > abs(intersectDistanceY) {
                        checkEntryTime = distanceX != 0 ? Float(intersectDistanceX / CGFloat(distanceX)) : Float.infinity
                    } else {
                        checkEntryTime = distanceY != 0 ? Float(intersectDistanceY / CGFloat(distanceY)) : Float.infinity
                    }
                    if checkEntryTime < entryTime {
                        entryTime = checkEntryTime
                        hitLineIndex = index
                    }
                    entryTime = min(entryTime, checkEntryTime)
                }
            }
        }
        
        // Check collision time and return result
        if entryTime < 0 && abs(entryTime * distanceX) < 0.0001 && abs(entryTime * distanceY) < 0.0001 {
            entryTime = 0
        }
        if entryTime >= 0 && entryTime <= 1 && hitLineIndex >= 0 {
            return CollisionResult(distanceX: distanceX * entryTime, distanceY: distanceY * entryTime, normal: collisionLines[hitLineIndex].perpendicular().unit())
        }
        return nil
    }
    
    private func createCollisionPolygon(object: PhysicsObject, targetObject: PhysicsObject) -> Polygon {
        // Create polygons of rotated square shapes
        let objectPolygon = Polygon(rect: object.collisionBounds, pivot: object.collisionPivot, rotation: CGFloat(object.collisionRotation))
        let targetObjectPolygon = Polygon(rect: targetObject.collisionBounds, pivot: targetObject.collisionPivot, rotation: CGFloat(targetObject.collisionRotation))
        var objectIndex = (objectPolygon.mostTopRightIndex() + 2) % 4
        var targetObjectIndex = targetObjectPolygon.mostTopRightIndex()
        
        // Determine how to follow the shape when overlapping the polygon on the target polygon's points
        let objectDistanceX = objectPolygon.points[objectIndex].x - objectPolygon.points[(objectIndex + 1) % 4].x
        let objectDistanceY = objectPolygon.points[objectIndex].y - objectPolygon.points[(objectIndex + 1) % 4].y
        let targetObjectDistanceX = targetObjectPolygon.points[(targetObjectIndex + 1) % 4].x - targetObjectPolygon.points[targetObjectIndex].x
        let targetObjectDistanceY = targetObjectPolygon.points[(targetObjectIndex + 1) % 4].y - targetObjectPolygon.points[targetObjectIndex].y
        let objectSlope = objectDistanceY != 0 ? objectDistanceX / objectDistanceY : CGFloat.infinity
        let targetObjectSlope = targetObjectDistanceY != 0 ? targetObjectDistanceX / targetObjectDistanceY : CGFloat.infinity
        if objectSlope > targetObjectSlope {
            objectIndex = (objectIndex + 1) % 4
        }

        // Overlap object polygon on the points of the target polygon and trace their edges
        let result = Polygon()
        for i in 0..<8 {
            let x = targetObjectPolygon.points[targetObjectIndex].x - objectPolygon.points[objectIndex].x
            let y = targetObjectPolygon.points[targetObjectIndex].y - objectPolygon.points[objectIndex].y
            result.addPoint(CGPoint(x: x, y: y))
            if i % 2 == 0 {
                targetObjectIndex = (targetObjectIndex + 1) % 4
            } else {
                objectIndex = (objectIndex + 1) % 4
            }
        }
        return result
    }
    
}

fileprivate class CollisionResult {
    
    let distanceX: Float
    let distanceY: Float
    let normal: Vector
    
    init(distanceX: Float, distanceY: Float, normal: Vector) {
        self.distanceX = distanceX
        self.distanceY = distanceY
        self.normal = normal
    }
    
}
