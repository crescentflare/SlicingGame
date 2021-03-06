//
//  SpriteCanvas.swift
//  Sprite core: a canvas to easily draw pixel independent sprites
//

import UIKit

class SpriteCanvas {

    // --
    // MARK: Members
    // --
    
    let gridWidth: CGFloat
    let gridHeight: CGFloat
    private let context: CGContext
    private let canvasWidth: CGFloat
    private let canvasHeight: CGFloat
    private let scaleX: CGFloat
    private let scaleY: CGFloat

    
    // --
    // MARK: Initialization
    // --
    
    init(context: CGContext, canvasWidth: CGFloat, canvasHeight: CGFloat, gridWidth: CGFloat, gridHeight: CGFloat) {
        self.context = context
        self.canvasWidth = canvasWidth
        self.canvasHeight = canvasHeight
        self.gridWidth = gridWidth
        self.gridHeight = gridHeight
        scaleX = gridWidth > 0 ? canvasWidth / self.gridWidth : 1
        scaleY = gridHeight > 0 ? canvasHeight / self.gridHeight : 1
    }

    
    // --
    // MARK: Drawing shapes
    // --

    func fillRect(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat, color: UIColor) {
        context.setFillColor(color.cgColor)
        context.fill(CGRect(x: x * scaleX, y: y * scaleY, width: width * scaleX, height: height * scaleY))
    }
    
    func fillRotatedRect(centerX: CGFloat, centerY: CGFloat, width: CGFloat, height: CGFloat, color: UIColor, rotation: CGFloat) {
        context.setFillColor(color.cgColor)
        context.saveGState()
        context.scaleBy(x: scaleX, y: scaleY)
        context.translateBy(x: centerX, y: centerY)
        context.rotate(by: rotation * CGFloat.pi * 2 / 360)
        context.fill(CGRect(x: -width / 2, y: -height / 2, width: width, height: height))
        context.restoreGState()
    }

}
