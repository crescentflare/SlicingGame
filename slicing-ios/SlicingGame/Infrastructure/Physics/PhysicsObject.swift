//
//  PhysicsObject.swift
//  Physics: an object in the physics engine
//

import UIKit

protocol PhysicsObject: class {

    var x: Float { get set }
    var y: Float { get set }
    var collisionBounds: CGRect { get }
    
    func didCollide(withObject: PhysicsObject?, side: CollisionSide, timeRemaining: TimeInterval, physics: Physics)

}
