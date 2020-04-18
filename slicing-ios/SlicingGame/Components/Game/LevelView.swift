//
//  LevelView.swift
//  Game view: contains all components for the playable level area
//

import UIKit
import UniLayout
import JsonInflator

protocol LevelViewDelegate: class {
    
    func didLethalHit()
    
}

class LevelView: FrameContainerView, PhysicsDelegate {
    
    // --
    // MARK: Members
    // --
    
    weak var delegate: LevelViewDelegate?
    private var backgroundView = ImageView()
    private var canvasViews = [LevelCanvasView()]
    private var spriteContainerView = SpriteContainerView()
    private var progressView = TextView()
    private let progressViewMargin = AppDimensions.text + 8


    // --
    // MARK: Viewlet integration
    // --

    override class func viewlet() -> JsonInflatable {
        return ViewletClass()
    }
    
    private class ViewletClass: JsonInflatable {
        
        func create() -> Any {
            return LevelView()
        }
        
        func update(convUtil: InflatorConvUtil, object: Any, attributes: [String: Any], parent: Any?, binder: InflatorBinder?) -> Bool {
            if let level = object as? LevelView {
                // Apply level size
                level.levelWidth = convUtil.asFloat(value: attributes["levelWidth"]) ?? 1
                level.levelHeight = convUtil.asFloat(value: attributes["levelHeight"]) ?? 1
                level.sliceWidth = convUtil.asFloat(value: attributes["sliceWidth"]) ?? 0

                // Apply background
                level.backgroundImage = ImageSource.fromValue(value: attributes["backgroundImage"])
                
                // Apply clear goal
                level.requireClearRate = convUtil.asInt(value: attributes["requireClearRate"]) ?? 100
                
                // Apply update frames per second
                level.fps = convUtil.asInt(value: attributes["fps"]) ?? 60

                // Apply debug settings
                level.drawPhysicsBoundaries = convUtil.asBool(value: attributes["drawPhysicsBoundaries"]) ?? false

                // Apply sprites
                level.clearSprites()
                if let spriteList = attributes["sprites"] as? [[String: Any]] {
                    for spriteItem in spriteList {
                        let sprite = Sprite()
                        sprite.x = convUtil.asFloat(value: spriteItem["x"]) ?? 0
                        sprite.y = convUtil.asFloat(value: spriteItem["y"]) ?? 0
                        sprite.width = convUtil.asFloat(value: spriteItem["width"]) ?? 1
                        sprite.height = convUtil.asFloat(value: spriteItem["height"]) ?? 1
                        level.addSprite(sprite)
                    }
                }

                // Apply slices
                let sliceArray = convUtil.asFloatArray(value: attributes["slices"])
                level.resetSlices()
                for index in sliceArray.indices {
                    if index % 4 == 0 && index + 3 < sliceArray.count {
                        level.slice(vector: Vector(start: CGPoint(x: CGFloat(sliceArray[index]), y: CGFloat(sliceArray[index + 1])), end: CGPoint(x: CGFloat(sliceArray[index + 2]), y: CGFloat(sliceArray[index + 3]))))
                    }
                }

                // Generic view properties
                ViewletUtil.applyGenericViewAttributes(convUtil: convUtil, view: level, attributes: attributes)
                return true
            }
            return false
        }
        
        func canRecycle(convUtil: InflatorConvUtil, object: Any, attributes: [String: Any]) -> Bool {
            return type(of: object) == LevelView.self
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
        // Add background
        backgroundView.layoutProperties.width = UniLayoutProperties.stretchToParent
        backgroundView.layoutProperties.height = UniLayoutProperties.stretchToParent
        backgroundView.layoutProperties.margin.bottom = progressViewMargin
        backgroundView.internalImageView.contentMode = .scaleAspectFill
        addSubview(backgroundView)

        // Add level canvas
        canvasViews[0].layoutProperties.width = UniLayoutProperties.stretchToParent
        canvasViews[0].layoutProperties.height = UniLayoutProperties.stretchToParent
        canvasViews[0].layoutProperties.margin.bottom = progressViewMargin
        canvasViews[0].backgroundColor = .white
        addSubview(canvasViews[0])

        // Add sprite container
        spriteContainerView.layoutProperties.width = UniLayoutProperties.stretchToParent
        spriteContainerView.layoutProperties.height = UniLayoutProperties.stretchToParent
        spriteContainerView.layoutProperties.margin.bottom = progressViewMargin
        spriteContainerView.backgroundColor = .clear
        spriteContainerView.physicsDelegate = self
        addSubview(spriteContainerView)

        // Add progress view
        progressView.layoutProperties.width = UniLayoutProperties.stretchToParent
        progressView.layoutProperties.verticalGravity = 1
        progressView.numberOfLines = 1
        progressView.textAlignment = .center
        progressView.text = "\(Int(canvasViews[0].clearRate())) / \(requireClearRate)%"
        addSubview(progressView)
    }
    
    
    // --
    // MARK: Sprites
    // --
    
    func addSprite(_ sprite: Sprite) {
        spriteContainerView.addSprite(sprite)
    }
    
    func clearSprites() {
        spriteContainerView.clearSprites()
    }


    // --
    // MARK: Slicing
    // --
    
    func slice(vector: Vector) {
        // Prepare slice vectors
        let topLeft = CGPoint(x: 0, y: 0)
        let bottomRight = CGPoint(x: CGFloat(levelWidth), y: CGFloat(levelHeight))
        let offsetVector = vector.perpendicular().unit() * CGFloat(sliceWidth / 2)
        let sliceVector = vector.translated(translateX: -offsetVector.x, translateY: -offsetVector.y).stretchedToEdges(topLeft: topLeft, bottomRight: bottomRight)
        let reversedVector = vector.reversed().translated(translateX: offsetVector.x, translateY: offsetVector.y).stretchedToEdges(topLeft: topLeft, bottomRight: bottomRight)
        
        // Check for collision
        let slicePolygon = Polygon(points: [ sliceVector.end, sliceVector.start, reversedVector.end, reversedVector.start ])
        if spriteContainerView.spritesOnPolygon(polygon: slicePolygon) {
            didLethalCollision()
            return
        }

        // Apply slice
        let originalCanvasViews = canvasViews
        for canvasView in originalCanvasViews {
            let normalClearRate = canvasView.clearRateForSlice(vector: sliceVector)
            let reversedClearRate = canvasView.clearRateForSlice(vector: reversedVector)
            let normalSpriteCount = spriteContainerView.spritesPerSlice(vector: sliceVector, inPolygon: canvasView.slicedBoundary)
            let reversedSpriteCount = spriteContainerView.spritesPerSlice(vector: reversedVector, inPolygon: canvasView.slicedBoundary)
            if normalSpriteCount > 0 && reversedSpriteCount > 0 {
                if let duplicateCanvasView = canvasView.copy() as? LevelCanvasView {
                    canvasViews.append(duplicateCanvasView)
                    insertSubview(duplicateCanvasView, belowSubview: canvasView)
                    duplicateCanvasView.slice(vector: reversedVector)
                }
                canvasView.slice(vector: sliceVector)
            } else if reversedSpriteCount > normalSpriteCount || (reversedSpriteCount == normalSpriteCount && reversedClearRate < normalClearRate) {
                canvasView.slice(vector: reversedVector)
            } else {
                canvasView.slice(vector: sliceVector)
            }
        }
        
        // Update state
        let remainingProgress = canvasViews.map { $0.remainingSliceArea() }.reduce(0, +)
        spriteContainerView.visibility = cleared() ? .invisible : .visible
        spriteContainerView.clearCollisionBoundaries()
        for canvasView in canvasViews {
            canvasView.visibility = cleared() ? .invisible : .visible
            spriteContainerView.addCollisionBoundaries(fromPolygon: canvasView.slicedBoundary)
        }
        progressView.text = "\(Int(100 - remainingProgress)) / \(requireClearRate)%"
    }

    func resetSlices() {
        // Remove duplicated canvas views and reset slices on the original one
        for canvasView in canvasViews {
            if canvasView !== canvasViews.first {
                canvasView.removeFromSuperview()
            }
        }
        canvasViews = [canvasViews[0]]
        canvasViews[0].resetSlices()
        
        // Update state
        let remainingProgress = canvasViews.map { $0.remainingSliceArea() }.reduce(0, +)
        spriteContainerView.visibility = cleared() ? .invisible : .visible
        spriteContainerView.clearCollisionBoundaries()
        for canvasView in canvasViews {
            canvasView.visibility = cleared() ? .invisible : .visible
            spriteContainerView.addCollisionBoundaries(fromPolygon: canvasView.slicedBoundary)
        }
        progressView.text = "\(Int(100 - remainingProgress)) / \(requireClearRate)%"
    }
    
    func transformedSliceVector(vector: Vector) -> Vector {
        let translatedVector = vector.translated(translateX: -frame.origin.x, translateY: -frame.origin.y)
        return translatedVector.scaled(scaleX: CGFloat(levelWidth) / canvasViews[0].frame.width, scaleY: CGFloat(levelHeight) / canvasViews[0].frame.height)
    }
    
    @discardableResult func setSliceVector(vector: Vector?, screenSpace: Bool = false) -> Bool {
        let sliceVector: Vector?
        if let vector = vector {
            sliceVector = screenSpace ? transformedSliceVector(vector: vector) : vector
        } else {
            sliceVector = nil
        }
        if sliceVector?.isValid() ?? false {
            return spriteContainerView.setSliceVector(vector: sliceVector)
        }
        return spriteContainerView.setSliceVector(vector: nil)
    }
    

    // --
    // MARK: Obtain state
    // --
    
    func cleared() -> Bool {
        let remainingProgress = canvasViews.map { $0.remainingSliceArea() }.reduce(0, +)
        return Int(100 - remainingProgress) >= requireClearRate
    }
    

    // --
    // MARK: Configurable values
    // --
    
    var levelWidth: Float = 1 {
        didSet {
            for canvasView in canvasViews {
                canvasView.canvasWidth = levelWidth
            }
            spriteContainerView.gridWidth = levelWidth
        }
    }

    var levelHeight: Float = 1 {
        didSet {
            for canvasView in canvasViews {
                canvasView.canvasHeight = levelHeight
            }
            spriteContainerView.gridHeight = levelHeight
        }
    }
    
    var sliceWidth: Float = 0 {
        didSet {
            spriteContainerView.sliceWidth = sliceWidth
            spriteContainerView.clearCollisionBoundaries()
            for canvasView in canvasViews {
                spriteContainerView.addCollisionBoundaries(fromPolygon: canvasView.slicedBoundary)
            }
        }
    }
    
    var backgroundImage: ImageSource? {
        set {
            backgroundView.source = newValue
        }
        get { return backgroundView.source }
    }
    
    var requireClearRate: Int = 100 {
        didSet {
            let remainingProgress = canvasViews.map { $0.remainingSliceArea() }.reduce(0, +)
            for canvasView in canvasViews {
                canvasView.visibility = cleared() ? .invisible : .visible
            }
            progressView.text = "\(Int(100 - remainingProgress)) / \(requireClearRate)%"
            spriteContainerView.visibility = cleared() ? .invisible : .visible
        }
    }
    
    var fps: Int {
        set {
            spriteContainerView.fps = newValue
        }
        get { return spriteContainerView.fps }
    }

    var drawPhysicsBoundaries: Bool {
        set {
            spriteContainerView.drawPhysicsBoundaries = newValue
        }
        get { return spriteContainerView.drawPhysicsBoundaries }
    }

    
    // --
    // MARK: Physics delegate
    // --
    
    func didLethalCollision() {
        delegate?.didLethalHit()
    }
    

    // --
    // MARK: Custom layout
    // --
    
    override func measuredSize(sizeSpec: CGSize, widthSpec: UniMeasureSpec, heightSpec: UniMeasureSpec) -> CGSize {
        var result = canvasViews[0].measuredSize(sizeSpec: sizeSpec, widthSpec: widthSpec, heightSpec: heightSpec)
        result.height += progressViewMargin
        return result
    }

}
