//
//  Sprite.swift
//  Sprite core: a single sprite within a sprite container
//

import UIKit

class Sprite {

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
    // MARK: Movement
    // --
    
    func update(timeInterval: TimeInterval, gridWidth: Float, gridHeight: Float) {
        x += moveX * Float(timeInterval)
        y += moveY * Float(timeInterval)
        if moveX > 0 && x + width > gridWidth {
            x = gridWidth - width
            moveX = -moveX
        } else if moveX < 0 && x < 0 {
            x = 0
            moveX = -moveX
        }
        if moveY > 0 && y + height > gridHeight {
            y = gridHeight - height
            moveY = -moveY
        } else if moveY < 0 && y < 0 {
            y = 0
            moveY = -moveY
        }
    }


    // --
    // MARK: Drawing
    // --

    func draw(canvas: SpriteCanvas) {
        canvas.fillRect(x: CGFloat(x), y: CGFloat(y), width: CGFloat(width), height: CGFloat(height), color: .black)
    }

}
