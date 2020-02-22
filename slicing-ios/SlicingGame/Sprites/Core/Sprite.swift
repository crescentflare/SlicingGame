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
    var width: Float = 32
    var height: Float = 32

    
    // --
    // MARK: Initialization
    // --
    
    init() {
        // No implementation
    }

    
    // --
    // MARK: Drawing
    // --

    func draw(context: CGContext) {
        context.setFillColor(UIColor.black.cgColor)
        context.fill(CGRect(x: CGFloat(x), y: CGFloat(y), width: CGFloat(width), height: CGFloat(height)))
    }

}
