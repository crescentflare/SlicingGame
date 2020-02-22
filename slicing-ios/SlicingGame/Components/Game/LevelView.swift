//
//  LevelView.swift
//  Game view: contains all components for the playable level area
//

import UIKit
import UniLayout
import JsonInflator

class LevelView: FrameContainerView {
    
    // --
    // MARK: Members
    // --
    
    private var backgroundView = ImageView()
    private var canvasView = LevelCanvasView()
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

        // Add progress view
        progressView.layoutProperties.width = UniLayoutProperties.stretchToParent
        progressView.layoutProperties.verticalGravity = 1
        progressView.numberOfLines = 1
        progressView.textAlignment = .center
        progressView.text = "\(Int(canvasView.clearRate())) / \(requireClearRate)%"
        addSubview(progressView)
    }
    
    
    // --
    // MARK: Slicing
    // --
    
    func slice(vector: Vector) {
        let normalClearRate = canvasView.clearRateForSlice(vector: vector)
        let reversedClearRate = canvasView.clearRateForSlice(vector: vector.reversed())
        if reversedClearRate < normalClearRate {
            canvasView.slice(vector: vector.reversed())
        } else {
            canvasView.slice(vector: vector)
        }
        progressView.text = "\(Int(canvasView.clearRate())) / \(requireClearRate)%"
        canvasView.visibility = cleared() ? .invisible : .visible
    }

    func resetSlices() {
        canvasView.resetSlices()
        progressView.text = "\(Int(canvasView.clearRate())) / \(requireClearRate)%"
        canvasView.visibility = cleared() ? .invisible : .visible
    }
    
    func transformedSliceVector(vector: Vector) -> Vector {
        let translatedVector = vector.translated(translateX: -frame.origin.x, translateY: -frame.origin.y)
        return translatedVector.scaled(scaleX: CGFloat(levelWidth) / canvasView.frame.width, scaleY: CGFloat(levelHeight) / canvasView.frame.height)
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
        }
    }

    var levelHeight: Float = 1 {
        didSet {
            canvasView.canvasHeight = levelHeight
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
        }
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
