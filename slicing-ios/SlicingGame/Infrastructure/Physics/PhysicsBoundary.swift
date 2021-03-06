//
//  PhysicsBoundary.swift
//  Physics: a solid boundary surrounding the physics engine's space
//

import UIKit

class PhysicsBoundary: PhysicsObject {
    
    // --
    // MARK: Members
    // --

    var x: Float = 0
    var y: Float = 0
    var width: Float = 1
    var height: Float = 1
    var rotation: Float = 0
    var lethal = false
    var recursiveCheck = 0


    // --
    // MARK: Initialization
    // --
    
    init(x: Float, y: Float, width: Float, height: Float, rotation: Float = 0) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        self.rotation = rotation
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
            return CGPoint(x: CGFloat(width / 2), y: CGFloat(height / 2))
        }
    }


    // --
    // MARK: Physics
    // --

    func didCollide(withObject: PhysicsObject?, normal: Vector, timeRemaining: TimeInterval, physics: Physics) {
        // No implementation
    }

}
