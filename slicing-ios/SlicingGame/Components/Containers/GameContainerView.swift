//
//  GameContainerView.swift
//  Container view: layout of game components and slice interaction
//

import UIKit
import UniLayout
import JsonInflator

class GameContainerView: FrameContainerView {
    
    // --
    // MARK: Members
    // --
    
    private var canvasView = LevelCanvasView()


    // --
    // MARK: Viewlet integration
    // --

    override class func viewlet() -> JsonInflatable {
        return ViewletClass()
    }
    
    private class ViewletClass: JsonInflatable {
        
        func create() -> Any {
            return GameContainerView()
        }
        
        func update(convUtil: InflatorConvUtil, object: Any, attributes: [String: Any], parent: Any?, binder: InflatorBinder?) -> Bool {
            if let gameContainer = object as? GameContainerView {
                // Apply canvas size
                gameContainer.levelWidth = convUtil.asFloat(value: attributes["levelWidth"]) ?? 1
                gameContainer.levelHeight = convUtil.asFloat(value: attributes["levelHeight"]) ?? 1
                
                // Apply slices
                let sliceArray = convUtil.asFloatArray(value: attributes["slices"])
                gameContainer.resetSlices()
                for index in sliceArray.indices {
                    if index % 4 == 0 && index + 3 < sliceArray.count {
                        gameContainer.slice(vector: Vector(start: CGPoint(x: CGFloat(sliceArray[index]), y: CGFloat(sliceArray[index + 1])), end: CGPoint(x: CGFloat(sliceArray[index + 2]), y: CGFloat(sliceArray[index + 3]))))
                    }
                }

                // Generic view properties
                ViewletUtil.applyGenericViewAttributes(convUtil: convUtil, view: gameContainer, attributes: attributes)
                return true
            }
            return false
        }
        
        func canRecycle(convUtil: InflatorConvUtil, object: Any, attributes: [String: Any]) -> Bool {
            return type(of: object) == GameContainerView.self
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
        let margin = AppDimensions.pagePadding
        canvasView.layoutProperties.margin = UIEdgeInsets(top: margin, left: margin, bottom: margin, right: margin)
        canvasView.layoutProperties.horizontalGravity = 0.5
        canvasView.layoutProperties.verticalGravity = 0.5
        canvasView.backgroundColor = .white
        addSubview(canvasView)
    }
    
    
    // --
    // MARK: Slicing
    // --
    
    func slice(vector: Vector) {
        canvasView.slice(vector: vector)
    }

    func resetSlices() {
        canvasView.resetSlices()
    }
    

    // --
    // MARK: Configurable values
    // --
    
    var levelWidth: Float = 1 {
        didSet {
            canvasView.canvasWidth = levelWidth
        }
    }

    var levelHeight: Float = 1 {
        didSet {
            canvasView.canvasHeight = levelHeight
        }
    }
    
}
