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
    // MARK: Properties
    // --
    
    var collisionBounds: CGRect {
        get {
            return CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height))
        }
    }
    

    // --
    // MARK: Movement
    // --
    
    func update(timeInterval: TimeInterval, physics: Physics) {
        physics.moveObject(self, distanceX: moveX * Float(timeInterval), distanceY: moveY * Float(timeInterval))
    }


    // --
    // MARK: Physics
    // --
    
    func didCollide(withObject: PhysicsObject?, side: CollisionSide, physics: Physics) {
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
    }
    

    // --
    // MARK: Drawing
    // --

    func draw(canvas: SpriteCanvas) {
        canvas.fillRect(x: CGFloat(x), y: CGFloat(y), width: CGFloat(width), height: CGFloat(height), color: .black)
    }

}
