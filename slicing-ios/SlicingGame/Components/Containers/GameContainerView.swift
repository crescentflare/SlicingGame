//
//  GameContainerView.swift
//  Container view: layout of game components and slice interaction
//

import UIKit
import UniLayout
import JsonInflator

class GameContainerView: FrameContainerView, LevelViewDelegate {
    
    // --
    // MARK: Statics
    // --
    
    private let minimumDragDistance: CGFloat = 32


    // --
    // MARK: Members
    // --
    
    private var levelView = LevelView()
    private var slicePreviewView = LevelSlicePreviewView()
    private var currentSlice: LevelViewSliceResult?
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
                // Apply level size
                gameContainer.levelWidth = convUtil.asFloat(value: attributes["levelWidth"]) ?? 1
                gameContainer.levelHeight = convUtil.asFloat(value: attributes["levelHeight"]) ?? 1
                gameContainer.sliceWidth = convUtil.asFloat(value: attributes["sliceWidth"]) ?? 0
                
                // Apply background
                gameContainer.backgroundImage = ImageSource.fromValue(value: attributes["backgroundImage"])

                // Apply clear goal
                gameContainer.requireClearRate = convUtil.asInt(value: attributes["requireClearRate"]) ?? 100

                // Apply events
                gameContainer.clearEvent = AppEvent.fromValue(value: attributes["clearEvent"])
                gameContainer.lethalHitEvent = AppEvent.fromValue(value: attributes["lethalHitEvent"])

                // Apply update frames per second
                gameContainer.fps = convUtil.asInt(value: attributes["fps"]) ?? 60

                // Apply debug settings
                gameContainer.drawPhysicsBoundaries = convUtil.asBool(value: attributes["drawPhysicsBoundaries"]) ?? false

                // Apply sprites
                gameContainer.clearSprites()
                if let spriteList = attributes["sprites"] as? [[String: Any]] {
                    for spriteItem in spriteList {
                        let sprite = Sprite()
                        sprite.x = convUtil.asFloat(value: spriteItem["x"]) ?? 0
                        sprite.y = convUtil.asFloat(value: spriteItem["y"]) ?? 0
                        sprite.width = convUtil.asFloat(value: spriteItem["width"]) ?? 1
                        sprite.height = convUtil.asFloat(value: spriteItem["height"]) ?? 1
                        gameContainer.addSprite(sprite)
                    }
                }

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

                // Chain event observer
                if let eventObserver = parent as? AppEventObserver {
                    gameContainer.eventObserver = eventObserver
                }
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
        // Add level
        let margin = AppDimensions.pagePadding
        levelView.layoutProperties.margin = UIEdgeInsets(top: margin, left: margin, bottom: margin, right: margin)
        levelView.layoutProperties.horizontalGravity = 0.5
        levelView.layoutProperties.verticalGravity = 0.5
        levelView.delegate = self
        addSubview(levelView)
        
        // Add slice preview
        slicePreviewView.layoutProperties.width = UniLayoutProperties.stretchToParent
        slicePreviewView.layoutProperties.height = UniLayoutProperties.stretchToParent
        slicePreviewView.color = .slicePreviewLine
        addSubview(slicePreviewView)
    }
    
    
    // --
    // MARK: Sprites
    // --
    
    func addSprite(_ sprite: Sprite) {
        levelView.addSprite(sprite)
    }
    
    func clearSprites() {
        levelView.clearSprites()
    }


    // --
    // MARK: Slicing
    // --
    
    func slice(vector: Vector, restrictCanvasIndices: [Int]? = nil) {
        levelView.slice(vector: vector, restrictCanvasIndices: restrictCanvasIndices)
        if levelView.cleared() {
            if let clearEvent = clearEvent {
                eventObserver?.observedEvent(clearEvent, sender: self)
            }
        }
    }

    func resetSlices() {
        levelView.resetSlices()
    }
    

    // --
    // MARK: Configurable values
    // --
    
    var clearEvent: AppEvent?
    var lethalHitEvent: AppEvent?

    var levelWidth: Float = 1 {
        didSet {
            levelView.levelWidth = levelWidth
        }
    }

    var levelHeight: Float = 1 {
        didSet {
            levelView.levelHeight = levelHeight
        }
    }
    
    var sliceWidth: Float = 0 {
        didSet {
            levelView.sliceWidth = sliceWidth
        }
    }
    
    var backgroundImage: ImageSource? {
        set {
            levelView.backgroundImage = newValue
        }
        get { return levelView.backgroundImage }
    }

    var requireClearRate: Int {
        set {
            levelView.requireClearRate = newValue
        }
        get { return levelView.requireClearRate }
    }

    var fps: Int {
        set {
            levelView.fps = newValue
        }
        get { return levelView.fps }
    }

    var drawPhysicsBoundaries: Bool {
        set {
            levelView.drawPhysicsBoundaries = newValue
        }
        get { return levelView.drawPhysicsBoundaries }
    }

    
    // --
    // MARK: Level view delegate
    // --
    
    func didLethalHit() {
        currentSlice = nil
        dragStart = nil
        dragEnd = nil
        slicePreviewView.start = nil
        slicePreviewView.end = nil
        levelView.setSliceVector(vector: nil)
        if let lethalHitEvent = lethalHitEvent {
            eventObserver?.observedEvent(lethalHitEvent, sender: self)
        }
    }


    // --
    // MARK: Interaction
    // --
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        if !levelView.cleared() {
            if let touch = touches.first {
                dragStart = touch.location(in: self)
                dragEnd = dragStart
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        for touch in touches {
            if touch.previousLocation(in: self) == dragEnd {
                // Check if a slice can be made
                dragEnd = touch.location(in: self)
                if let dragStart = dragStart, let dragEnd = dragEnd {
                    let dragVector = Vector(start: dragStart, end: dragEnd)
                    if currentSlice != nil || dragVector.distance() >= minimumDragDistance {
                        currentSlice = levelView.validateSlice(vector: dragVector, screenSpace: true)
                    }
                } else {
                    currentSlice = nil
                }
                
                // Update view
                if let currentSlice = currentSlice {
                    dragStart = currentSlice.vector.start
                }
                slicePreviewView.start = currentSlice?.vector.start
                slicePreviewView.end = currentSlice?.vector.end
                levelView.setSliceVector(vector: currentSlice?.vector, screenSpace: true)
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        // Update the slice
        if let touch = touches.first {
            dragEnd = touch.location(in: self)
            if let dragStart = dragStart, let dragEnd = dragEnd {
                let dragVector = Vector(start: dragStart, end: dragEnd)
                if currentSlice != nil || dragVector.distance() >= minimumDragDistance {
                    currentSlice = levelView.validateSlice(vector: dragVector, screenSpace: true)
                }
            } else {
                currentSlice = nil
            }
        }
        
        // Apply slice if possible
        if let currentSlice = currentSlice {
            let transformedVector = levelView.transformedSliceVector(vector: currentSlice.vector)
            if transformedVector.isValid() && levelView.setSliceVector(vector: transformedVector) {
                slice(vector: transformedVector, restrictCanvasIndices: currentSlice.canvasIndices)
            }
        }
        
        // Reset state
        currentSlice = nil
        dragStart = nil
        dragEnd = nil
        slicePreviewView.start = nil
        slicePreviewView.end = nil
        levelView.setSliceVector(vector: nil)
    }

}
