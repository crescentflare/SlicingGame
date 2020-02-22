//
//  SpriteContainerView.swift
//  Container view: provides a container for managing sprites
//

import UIKit
import UniLayout
import JsonInflator

class SpriteContainerView: FrameContainerView {
    
    // --
    // MARK: Members
    // --
    
    private var sprites = [Sprite]()


    // --
    // MARK: Viewlet integration
    // --

    override class func viewlet() -> JsonInflatable {
        return ViewletClass()
    }
    
    private class ViewletClass: JsonInflatable {
        
        func create() -> Any {
            return SpriteContainerView()
        }
        
        func update(convUtil: InflatorConvUtil, object: Any, attributes: [String: Any], parent: Any?, binder: InflatorBinder?) -> Bool {
            if let spriteContainer = object as? SpriteContainerView {
                // Apply canvas size
                spriteContainer.gridWidth = convUtil.asFloat(value: attributes["gridWidth"]) ?? 1
                spriteContainer.gridHeight = convUtil.asFloat(value: attributes["gridHeight"]) ?? 1

                // Apply sprites
                spriteContainer.clearSprites()
                if let spriteList = attributes["sprites"] as? [[String: Any]] {
                    for spriteItem in spriteList {
                        let sprite = Sprite()
                        sprite.x = convUtil.asFloat(value: spriteItem["x"]) ?? 0
                        sprite.y = convUtil.asFloat(value: spriteItem["y"]) ?? 0
                        sprite.width = convUtil.asFloat(value: spriteItem["width"]) ?? 1
                        sprite.height = convUtil.asFloat(value: spriteItem["height"]) ?? 1
                        spriteContainer.addSprite(sprite)
                    }
                }

                // Generic view properties
                ViewletUtil.applyGenericViewAttributes(convUtil: convUtil, view: spriteContainer, attributes: attributes)
                return true
            }
            return false
        }
        
        func canRecycle(convUtil: InflatorConvUtil, object: Any, attributes: [String: Any]) -> Bool {
            return type(of: object) == SpriteContainerView.self
        }
        
    }
    
    
    // --
    // MARK: Initialization
    // --
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func setup() {
        // No implementation
    }
    
    
    // --
    // MARK: Sprites
    // --
    
    func addSprite(_ sprite: Sprite) {
        sprites.append(sprite)
    }
    
    func clearSprites() {
        sprites.removeAll()
    }


    // --
    // MARK: Configurable values
    // --
    
    var gridWidth: Float = 1 {
        didSet {
            if gridWidth != oldValue {
                UniLayout.setNeedsLayout(view: self)
            }
        }
    }

    var gridHeight: Float = 1 {
        didSet {
            if gridHeight != oldValue {
                UniLayout.setNeedsLayout(view: self)
            }
        }
    }


    // --
    // MARK: Drawing
    // --
    
    override func draw(_ rect: CGRect) {
        if let context = UIGraphicsGetCurrentContext() {
            let spriteCanvas = SpriteCanvas(context: context, canvasWidth: bounds.width, canvasHeight: bounds.height, gridWidth: CGFloat(gridWidth), gridHeight: CGFloat(gridHeight))
            sprites.forEach {
                $0.draw(canvas: spriteCanvas)
            }
        }
    }

    
    // --
    // MARK: Custom layout
    // --
    
    override func measuredSize(sizeSpec: CGSize, widthSpec: UniMeasureSpec, heightSpec: UniMeasureSpec) -> CGSize {
        if widthSpec == .limitSize && heightSpec == .limitSize {
            if sizeSpec.width * CGFloat(gridHeight) / CGFloat(gridWidth) <= sizeSpec.height {
                return CGSize(width: sizeSpec.width, height: sizeSpec.width * CGFloat(gridHeight) / CGFloat(gridWidth))
            }
            return CGSize(width: sizeSpec.height * CGFloat(gridWidth) / CGFloat(gridHeight), height: sizeSpec.height)
        } else if widthSpec == .exactSize && heightSpec == .exactSize {
            return CGSize(width: sizeSpec.width, height: sizeSpec.height)
        } else if widthSpec == .limitSize || widthSpec == .exactSize {
            return CGSize(width: sizeSpec.width, height: sizeSpec.width * CGFloat(gridHeight) / CGFloat(gridWidth))
        } else if heightSpec == .limitSize || heightSpec == .exactSize {
            return CGSize(width: sizeSpec.height * CGFloat(gridWidth) / CGFloat(gridHeight), height: sizeSpec.height)
        }
        return super.measuredSize(sizeSpec: sizeSpec, widthSpec: widthSpec, heightSpec: heightSpec)
    }

}
