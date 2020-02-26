//
//  Sprite.swift
//  Sprite core: a single sprite within a sprite container
//

import UIKit

class Sprite: PhysicsObject {

    // --
    // MARK: Members
    // --
    
    var x: Float = 0
    var y: Float = 0
    var width: Float = 1
    var height: Float = 1
    var recursiveCheck = 0
    private var moveX: Float
    private var moveY: Float

    
    // --
    // MARK: Initialization
    // --
    
    init() {
        let moveVector = Vector(directionAngle: CGFloat.random(in: 0..<360)) * 4
        moveX = Float(moveVector.x)
        moveY = Float(moveVector.y)
    }

    
    // --
    // MARK: Collision properties
    // --
    
    var collisionBounds: CGRect {
        get {
            return CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height))
        }
    }
    
    var collisionRotation: Float {
        get {
            return 0
        }
    }
    
    var collisionPivot: CGPoint {
        get {
            return CGPoint(x: CGFloat(width) / 2, y: CGFloat(height) / 2)
        }
    }
    

    // --
    // MARK: Movement
    // --
    
    func update(timeInterval: TimeInterval, physics: Physics) {
        physics.moveObject(self, distanceX: moveX * Float(timeInterval), distanceY: moveY * Float(timeInterval), timeInterval: timeInterval)
    }


    // --
    // MARK: Physics
    // --
    
    func didCollide(withObject: PhysicsObject?, normal: Vector, timeRemaining: TimeInterval, physics: Physics) {
        let dotProduct = Float(normal.x) * moveX + Float(normal.y) * moveY
        let newMoveX = moveX - 2 * Float(normal.x) * dotProduct
        let newMoveY = moveY - 2 * Float(normal.y) * dotProduct
        let surfaceVector = normal.perpendicular().reversed()
        if surfaceVector.directionOf(point: CGPoint(x: CGFloat(newMoveX), y: CGFloat(newMoveY))) <= 0 {
            moveX = newMoveX
            moveY = newMoveY
        }
        if timeRemaining > 0 {
            update(timeInterval: timeRemaining, physics: physics)
        }
    }
    

    // --
    // MARK: Drawing
    // --

    func draw(canvas: SpriteCanvas) {
        canvas.fillRect(x: CGFloat(x), y: CGFloat(y), width: CGFloat(width), height: CGFloat(height), color: .black)
    }

}
