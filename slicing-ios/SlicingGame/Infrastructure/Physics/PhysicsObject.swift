//
//  PhysicsObject.swift
//  Physics: an object in the physics engine
//

import UIKit

protocol PhysicsObject: class {

    var x: Float { get set }
    var y: Float { get set }
    var recursiveCheck: Int { get set }
    var collisionBounds: CGRect { get }
    var collisionRotation: Float { get }
    var collisionPivot: CGPoint { get }
    
    func didCollide(withObject: PhysicsObject?, normal: Vector, timeRemaining: TimeInterval, physics: Physics)

}
