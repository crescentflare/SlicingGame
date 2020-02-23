//
//  Physics.swift
//  Physics: manages collision and send events to objects
//

import UIKit

enum CollisionSide {
    
    case left
    case right
    case top
    case bottom
    
    func flipped() -> CollisionSide {
        switch self {
        case .left:
            return .right
        case .right:
            return .left
        case .top:
            return .bottom
        case .bottom:
            return .top
        }
    }
    
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
    
    func clearObjects() {
        objects.removeAll { $0 !== leftBoundary && $0 !== rightBoundary && $0 !== topBoundary && $0 !== bottomBoundary }
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
        var collisionSide: CollisionSide?
        for checkObject in objects {
            if checkObject !== object {
                if let collision = checkObjectCollision(object: checkObject, distanceX: moveX, distanceY: moveY, bounds: bounds) {
                    moveX = collision.distanceX
                    moveY = collision.distanceY
                    collisionObject = checkObject
                    collisionSide = collision.side
                }
            }
        }
        
        // Move
        object.x += moveX
        object.y += moveY
        
        // Notify objects
        if let collisionSide = collisionSide {
            let timeRemaining = TimeInterval(1 - (distanceX > distanceY ? abs(moveX) / abs(distanceX) : abs(moveY) / abs(distanceY))) * timeInterval
            collisionObject?.didCollide(withObject: object, side: collisionSide.flipped(), timeRemaining: 0, physics: self)
            object.didCollide(withObject: collisionObject, side: collisionSide, timeRemaining: timeRemaining, physics: self)
        }
    }
    

    // --
    // MARK: Collision
    // --
    
    private func checkObjectCollision(object: PhysicsObject, distanceX: Float, distanceY: Float, bounds: CGRect) -> CollisionResult? {
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
            let side: CollisionSide
            if entryTimeX > entryTimeY {
                side = distanceX < 0 ? .left : .right
            } else {
                side = distanceY < 0 ? .top : .bottom
            }
            return CollisionResult(distanceX: distanceX * entryTime, distanceY: distanceY * entryTime, side: side)
        }
        return nil
    }

}

fileprivate class CollisionResult {
    
    let distanceX: Float
    let distanceY: Float
    let side: CollisionSide
    
    init(distanceX: Float, distanceY: Float, side: CollisionSide) {
        self.distanceX = distanceX
        self.distanceY = distanceY
        self.side = side
    }
    
}
