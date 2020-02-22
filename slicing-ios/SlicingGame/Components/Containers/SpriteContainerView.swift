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
    
    private var sprite = Sprite()


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
    // MARK: Drawing
    // --
    
    override func draw(_ rect: CGRect) {
        if let context = UIGraphicsGetCurrentContext() {
            sprite.draw(context: context)
        }
    }

}
