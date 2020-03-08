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
    private var canvasView = LevelCanvasView()
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
        canvasView.layoutProperties.width = UniLayoutProperties.stretchToParent
        canvasView.layoutProperties.height = UniLayoutProperties.stretchToParent
        canvasView.layoutProperties.margin.bottom = progressViewMargin
        canvasView.backgroundColor = .white
        addSubview(canvasView)

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
        progressView.text = "\(Int(canvasView.clearRate())) / \(requireClearRate)%"
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
        // Apply slice
        let reversedVector = vector.reversed()
        let normalClearRate = canvasView.clearRateForSlice(vector: vector)
        let reversedClearRate = canvasView.clearRateForSlice(vector: reversedVector)
        let normalSpriteCount = spriteContainerView.spritesPerSlice(vector: vector)
        let reversedSpriteCount = spriteContainerView.spritesPerSlice(vector: reversedVector)
        if reversedSpriteCount > normalSpriteCount || (reversedSpriteCount == normalSpriteCount && reversedClearRate < normalClearRate) {
            canvasView.slice(vector: reversedVector)
        } else {
            canvasView.slice(vector: vector)
        }
        
        // Update state
        progressView.text = "\(Int(canvasView.clearRate())) / \(requireClearRate)%"
        canvasView.visibility = cleared() ? .invisible : .visible
        spriteContainerView.visibility = cleared() ? .invisible : .visible
        spriteContainerView.generateCollisionBoundaries(fromPolygon: canvasView.slicedBoundary)
    }

    func resetSlices() {
        canvasView.resetSlices()
        progressView.text = "\(Int(canvasView.clearRate())) / \(requireClearRate)%"
        canvasView.visibility = cleared() ? .invisible : .visible
        spriteContainerView.visibility = cleared() ? .invisible : .visible
        spriteContainerView.generateCollisionBoundaries(fromPolygon: canvasView.slicedBoundary)
    }
    
    func transformedSliceVector(vector: Vector) -> Vector {
        let translatedVector = vector.translated(translateX: -frame.origin.x, translateY: -frame.origin.y)
        return translatedVector.scaled(scaleX: CGFloat(levelWidth) / canvasView.frame.width, scaleY: CGFloat(levelHeight) / canvasView.frame.height)
    }
    
    @discardableResult func setSliceVector(vector: Vector?, screenSpace: Bool = false) -> Bool {
        let sliceVector: Vector?
        if let vector = vector {
            sliceVector = screenSpace ? transformedSliceVector(vector: vector) : vector
        } else {
            sliceVector = nil
        }
        if sliceVector?.isValid() ?? false {
            let topLeft = CGPoint(x: CGFloat(-spriteContainerView.gridWidth * 4), y: CGFloat(-spriteContainerView.gridHeight * 4))
            let bottomRight = CGPoint(x: CGFloat(spriteContainerView.gridWidth * 4), y: CGFloat(spriteContainerView.gridHeight * 4))
            return spriteContainerView.setSliceVector(vector: sliceVector?.stretchedToEdges(topLeft: topLeft, bottomRight: bottomRight))
        }
        return spriteContainerView.setSliceVector(vector: nil)
    }
    

    // --
    // MARK: Obtain state
    // --
    
    func cleared() -> Bool {
        return Int(canvasView.clearRate()) >= requireClearRate
    }
    

    // --
    // MARK: Configurable values
    // --
    
    var levelWidth: Float = 1 {
        didSet {
            canvasView.canvasWidth = levelWidth
            spriteContainerView.gridWidth = levelWidth
        }
    }

    var levelHeight: Float = 1 {
        didSet {
            canvasView.canvasHeight = levelHeight
            spriteContainerView.gridHeight = levelHeight
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
            progressView.text = "\(Int(canvasView.clearRate())) / \(requireClearRate)%"
            canvasView.visibility = cleared() ? .invisible : .visible
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
        var result = canvasView.measuredSize(sizeSpec: sizeSpec, widthSpec: widthSpec, heightSpec: heightSpec)
        result.height += progressViewMargin
        return result
    }

}
