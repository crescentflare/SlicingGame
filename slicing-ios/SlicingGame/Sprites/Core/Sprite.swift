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
    var rotation: Float = 0
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
        rotation = Float.random(in: 0..<360)
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
            return rotation
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
    
    func didCollide(withObject: PhysicsObject?, side: CollisionSide, timeRemaining: TimeInterval, physics: Physics) {
        switch side {
        case .left:
            moveX = abs(moveX)
        case .right:
            moveX = -abs(moveX)
        case .top:
            moveY = abs(moveY)
        case .bottom:
            moveY = -abs(moveY)
        }
        if timeRemaining > 0 {
            update(timeInterval: timeRemaining, physics: physics)
        }
    }
    

    // --
    // MARK: Drawing
    // --

    func draw(canvas: SpriteCanvas) {
        canvas.fillRotatedRect(centerX: CGFloat(x + width / 2), centerY: CGFloat(y + height / 2), width: CGFloat(width), height: CGFloat(height), color: .black, rotation: CGFloat(rotation))
    }

}
