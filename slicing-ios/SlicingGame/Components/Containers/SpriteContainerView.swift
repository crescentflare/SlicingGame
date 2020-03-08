//
//  SpriteContainerView.swift
//  Container view: provides a container for managing sprites
//

import UIKit
import UniLayout
import JsonInflator

class SpriteContainerView: FrameContainerView, PhysicsDelegate {
    
    // --
    // MARK: Members
    // --
    
    weak var physicsDelegate: PhysicsDelegate?
    private let physics = Physics()
    private var sprites = [Sprite]()
    private var collisionBoundaries = [PhysicsBoundary]()
    private var sliceVectorBoundary: PhysicsBoundary?
    private var updateScheduled = false
    private var lastTimeInterval = Date.timeIntervalSinceReferenceDate
    private var timeCorrection = 0.001


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

                // Apply update frames per second
                spriteContainer.fps = convUtil.asInt(value: attributes["fps"]) ?? 60

                // Apply debug settings
                spriteContainer.drawPhysicsBoundaries = convUtil.asBool(value: attributes["drawPhysicsBoundaries"]) ?? false

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
        physics.delegate = self
    }
    
    
    // --
    // MARK: Sprites
    // --
    
    func addSprite(_ sprite: Sprite) {
        sprites.append(sprite)
        physics.registerObject(sprite)
    }
    
    func clearSprites() {
        for sprite in sprites {
            physics.unregisterObject(sprite)
        }
        sprites.removeAll()
    }


    // --
    // MARK: Collision boundaries
    // --
    
    func addCollisionBoundary(_ boundary: PhysicsBoundary) {
        collisionBoundaries.append(boundary)
        physics.registerObject(boundary)
    }
    
    func generateCollisionBoundaries(fromPolygon: Polygon) {
        clearCollisionBoundaries()
        for vector in fromPolygon.asVectorArray() {
            let halfDistanceX = vector.x / 2
            let halfDistanceY = vector.y / 2
            let vectorCenterX = vector.start.x + halfDistanceX
            let vectorCenterY = vector.start.y + halfDistanceY
            let centerX = vectorCenterX + halfDistanceY
            let centerY = vectorCenterY - halfDistanceX
            let vectorLength = vector.distance()
            let x = Float(centerX - vectorLength / 2)
            let y = Float(centerY - vectorLength / 2)
            let rotation = atan2(vector.x, vector.y) * 360 / (CGFloat.pi * 2)
            addCollisionBoundary(PhysicsBoundary(x: x, y: y, width: Float(vectorLength), height: Float(vectorLength), rotation: Float(-rotation)))
        }
    }
    
    func clearCollisionBoundaries() {
        for collisionBoundary in collisionBoundaries {
            physics.unregisterObject(collisionBoundary)
        }
        collisionBoundaries.removeAll()
    }


    // --
    // MARK: Slicing
    // --

    func setSliceVector(vector: Vector?) -> Bool {
        if let sliceVectorBoundary = sliceVectorBoundary {
            physics.unregisterObject(sliceVectorBoundary)
        }
        sliceVectorBoundary = nil
        if let vector = vector {
            let vectorCenterX = vector.start.x + vector.x / 2
            let vectorCenterY = vector.start.y + vector.y / 2
            let width: CGFloat = CGFloat(gridWidth) * 0.005
            let height = vector.distance()
            let x = Float(vectorCenterX - width / 2)
            let y = Float(vectorCenterY - height / 2)
            let rotation = atan2(vector.x, vector.y) * 360 / (CGFloat.pi * 2)
            let physicsBoundary = PhysicsBoundary(x: x, y: y, width: Float(width), height: Float(height), rotation: Float(-rotation))
            physicsBoundary.lethal = true
            physics.registerObject(physicsBoundary)
            sliceVectorBoundary = physicsBoundary
        }
        return true
    }

    
    // --
    // MARK: Configurable values
    // --
    
    var gridWidth: Float = 1 {
        didSet {
            if gridWidth != oldValue {
                UniLayout.setNeedsLayout(view: self)
            }
            physics.width = gridWidth
        }
    }

    var gridHeight: Float = 1 {
        didSet {
            if gridHeight != oldValue {
                UniLayout.setNeedsLayout(view: self)
            }
            physics.height = gridHeight
        }
    }

    var fps = 60
    
    var drawPhysicsBoundaries = false

    
    // --
    // MARK: Physics delegate
    // --
    
    func didLethalCollision() {
        physicsDelegate?.didLethalCollision()
    }


    // --
    // MARK: Movement
    // --
    
    private func update(timeInterval: TimeInterval) {
        physics.prepareObjects()
        sprites.forEach {
            $0.update(timeInterval: timeInterval, physics: physics)
        }
        setNeedsDisplay()
    }


    // --
    // MARK: Drawing
    // --
    
    override func draw(_ rect: CGRect) {
        // Draw sprites and optional physics boundaries
        if let context = UIGraphicsGetCurrentContext() {
            let spriteCanvas = SpriteCanvas(context: context, canvasWidth: bounds.width, canvasHeight: bounds.height, gridWidth: CGFloat(gridWidth), gridHeight: CGFloat(gridHeight))
            sprites.forEach {
                $0.draw(canvas: spriteCanvas)
            }
            if drawPhysicsBoundaries {
                for boundary in collisionBoundaries {
                    spriteCanvas.fillRotatedRect(centerX: CGFloat(boundary.x) + boundary.collisionPivot.x, centerY: CGFloat(boundary.y) + boundary.collisionPivot.y, width: CGFloat(boundary.width), height: CGFloat(boundary.height), color: .red, rotation: CGFloat(boundary.collisionRotation))
                }
                if let boundary = sliceVectorBoundary {
                    spriteCanvas.fillRotatedRect(centerX: CGFloat(boundary.x) + boundary.collisionPivot.x, centerY: CGFloat(boundary.y) + boundary.collisionPivot.y, width: CGFloat(boundary.width), height: CGFloat(boundary.height), color: .yellow, rotation: CGFloat(boundary.collisionRotation))
                }
            }
        }

        // Schedule next update
        if !updateScheduled {
            let checkTimeInterval = Date.timeIntervalSinceReferenceDate
            let delayTime = 1.0 / Double(fps) - (checkTimeInterval - lastTimeInterval)
            updateScheduled = true
            DispatchQueue.main.asyncAfter(deadline: .now() + max(0.001, delayTime - timeCorrection), execute: {
                // Try to correct for time lost due to dispatch queue inaccuracy
                let currentTimeInterval = Date.timeIntervalSinceReferenceDate
                if (delayTime >= 0.001) {
                    let lostTimeInterval = (currentTimeInterval - checkTimeInterval) - delayTime
                    if lostTimeInterval < -0.0001 {
                        self.timeCorrection -= 0.0001
                    } else if lostTimeInterval > 0.0001 {
                        self.timeCorrection += 0.0001
                    }
                }
                
                // Continue with the next update
                var difference = currentTimeInterval - self.lastTimeInterval
                self.lastTimeInterval = currentTimeInterval
                self.updateScheduled = false
                if difference > 1.0 / Double(self.fps) * 5 {
                    difference = 1.0 / Double(self.fps) * 5
                }
                self.update(timeInterval: difference)
            })
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
