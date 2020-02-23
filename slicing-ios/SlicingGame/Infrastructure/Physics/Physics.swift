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
    
    func moveObject(_ object: PhysicsObject, distanceX: Float, distanceY: Float) {
        // Check collision against other objects
        var moveX = distanceX
        var moveY = distanceY
        let startBounds = object.collisionBounds.offsetBy(dx: CGFloat(object.x), dy: CGFloat(object.y))
        var movedBounds = object.collisionBounds.offsetBy(dx: CGFloat(object.x) + CGFloat(moveX), dy: CGFloat(object.y) + CGFloat(moveY))
        var collisionObject: PhysicsObject?
        var collisionSide: CollisionSide?
        for checkObject in objects {
            if checkObject !== object {
                if let collision = checkObjectCollision(object: checkObject, distanceX: moveX, distanceY: moveY, startBounds: startBounds, endBounds: movedBounds) {
                    moveX = collision.distanceX
                    moveY = collision.distanceY
                    movedBounds = object.collisionBounds.offsetBy(dx: CGFloat(object.x) + CGFloat(moveX), dy: CGFloat(object.y) + CGFloat(moveY))
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
            collisionObject?.didCollide(withObject: object, side: collisionSide.flipped(), physics: self)
            object.didCollide(withObject: collisionObject, side: collisionSide, physics: self)
        }
    }
    

    // --
    // MARK: Collision
    // --
    
    private func checkObjectCollision(object: PhysicsObject, distanceX: Float, distanceY: Float, startBounds: CGRect, endBounds: CGRect) -> CollisionResult? {
        let objectBounds = object.collisionBounds.offsetBy(dx: CGFloat(object.x), dy: CGFloat(object.y))
        if endBounds.intersects(objectBounds) {
            // Handle collision with horizontal or vertical priority (depending if the start bounds were already intersecting with that axis)
            let preferHorizontalCollision = distanceY == 0 || (distanceY > 0 && startBounds.maxY >= objectBounds.minY) || (distanceY < 0 && startBounds.minY <= objectBounds.maxY)
            let preferVerticalCollision = distanceX == 0 || (distanceX > 0 && startBounds.maxX >= objectBounds.minX) || (distanceX < 0 && startBounds.minX <= objectBounds.maxX)
            if preferHorizontalCollision && distanceX != 0 {
                let side: CollisionSide = startBounds.minX < endBounds.minX ? .right : .left
                let newDistanceX = side == .right ? Float(objectBounds.minX - startBounds.maxX) : Float(objectBounds.maxX - startBounds.minX)
                return CollisionResult(distanceX: newDistanceX, distanceY: newDistanceX / distanceX * distanceY, side: side)
            } else if preferVerticalCollision && distanceY != 0 {
                let side: CollisionSide = startBounds.minY < endBounds.minY ? .bottom : .top
                let newDistanceY = side == .bottom ? Float(objectBounds.minY - startBounds.maxY) : Float(objectBounds.maxY - startBounds.minY)
                return CollisionResult(distanceX: newDistanceY / distanceY * distanceX, distanceY: newDistanceY, side: side)
            }
            
            // Handle remaining cases, collision side depends on the biggest overlap of the intersection
            let horizontalSide: CollisionSide = startBounds.minX < endBounds.minX ? .right : .left
            let verticalSide: CollisionSide = startBounds.minY < endBounds.minY ? .bottom : .top
            let intersectionWidth = horizontalSide == .right ? endBounds.maxX - objectBounds.minX : objectBounds.maxX - endBounds.minX
            let intersectionHeight = verticalSide == .bottom ? endBounds.maxY - objectBounds.minY : objectBounds.maxY - endBounds.minY
            if intersectionWidth > intersectionHeight && distanceY != 0 {
                let newDistanceY = verticalSide == .bottom ? Float(objectBounds.minY - startBounds.maxY) : Float(objectBounds.maxY - startBounds.minY)
                return CollisionResult(distanceX: newDistanceY / distanceY * distanceX, distanceY: newDistanceY, side: verticalSide)
            } else if distanceX != 0 {
                let newDistanceX = horizontalSide == .right ? Float(objectBounds.minX - startBounds.maxX) : Float(objectBounds.maxX - startBounds.minX)
                return CollisionResult(distanceX: newDistanceX, distanceY: newDistanceX / distanceX * distanceY, side: horizontalSide)
            }
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
