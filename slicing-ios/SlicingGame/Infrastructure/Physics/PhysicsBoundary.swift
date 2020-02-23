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


    // --
    // MARK: Initialization
    // --
    
    init(x: Float, y: Float, width: Float, height: Float) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
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
    // MARK: Physics
    // --

    func didCollide(withObject: PhysicsObject?, side: CollisionSide, timeRemaining: TimeInterval, physics: Physics) {
        // No implementation
    }

}
