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

    
    // --
    // MARK: Initialization
    // --
    
    init() {
        // No implementation
    }

    
    // --
    // MARK: Drawing
    // --

    func draw(canvas: SpriteCanvas) {
        canvas.fillRect(x: CGFloat(x), y: CGFloat(y), width: CGFloat(width), height: CGFloat(height), color: .black)
    }

}
