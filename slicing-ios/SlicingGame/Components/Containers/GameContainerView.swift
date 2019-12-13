//
//  GameContainerView.swift
//  Container view: layout of game components and slice interaction
//

import UIKit
import UniLayout
import JsonInflator

class GameContainerView: FrameContainerView {
    
    // --
    // MARK: Statics
    // --
    
    private let minimumDragDistance: CGFloat = 32


    // --
    // MARK: Members
    // --
    
    private var canvasView = LevelCanvasView()
    private var dragStart: CGPoint?
    private var dragEnd: CGPoint?


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
    
    
    // --
    // MARK: Interaction
    // --
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        if let touch = touches.first {
            dragStart = touch.location(in: self)
            dragEnd = dragStart
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        for touch in touches {
            if touch.previousLocation(in: self) == dragEnd {
                dragEnd = touch.location(in: self)
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        for touch in touches {
            if touch.previousLocation(in: self) == dragEnd {
                dragEnd = touch.location(in: self)
            }
        }
        if let dragStart = dragStart, let dragEnd = dragEnd, canvasView.frame.width > 0 && canvasView.frame.height > 0 {
            let viewVector = Vector(start: dragStart, end: dragEnd)
            if viewVector.distance() >= minimumDragDistance {
                let canvasVector = viewVector.translated(translateX: -canvasView.frame.origin.x, translateY: -canvasView.frame.origin.y)
                let sliceVector = canvasVector.scaled(scaleX: CGFloat(levelWidth) / canvasView.frame.width, scaleY: CGFloat(levelHeight) / canvasView.frame.height)
                if sliceVector.isValid() {
                    slice(vector: sliceVector.stretchedToEdges(topLeft: CGPoint(x: 0, y: 0), bottomRight: CGPoint(x: CGFloat(levelWidth), y: CGFloat(levelHeight))))
                }
            }
        }
        dragStart = nil
        dragEnd = nil
    }

}
