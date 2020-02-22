//
//  LevelCanvasView.swift
//  Game view: a level canvas layer
//

import UIKit
import UniLayout
import JsonInflator

class LevelCanvasView: UniView {
    
    // --
    // MARK: Members
    // --
    
    private var clipPolygon = Polygon(points: [ CGPoint(x: 0, y: 0), CGPoint(x: 1, y: 0), CGPoint(x: 1, y: 1), CGPoint(x: 0, y: 1) ])


    // --
    // MARK: Viewlet integration
    // --

    class func viewlet() -> JsonInflatable {
        return ViewletClass()
    }
    
    private class ViewletClass: JsonInflatable {
        
        func create() -> Any {
            return LevelCanvasView()
        }
        
        func update(convUtil: InflatorConvUtil, object: Any, attributes: [String: Any], parent: Any?, binder: InflatorBinder?) -> Bool {
            if let levelCanvas = object as? LevelCanvasView {
                // Apply canvas size
                levelCanvas.canvasWidth = convUtil.asFloat(value: attributes["canvasWidth"]) ?? 1
                levelCanvas.canvasHeight = convUtil.asFloat(value: attributes["canvasHeight"]) ?? 1
                
                // Apply slices
                let sliceArray = convUtil.asFloatArray(value: attributes["slices"])
                levelCanvas.resetSlices()
                for index in sliceArray.indices {
                    if index % 4 == 0 && index + 3 < sliceArray.count {
                        levelCanvas.slice(vector: Vector(start: CGPoint(x: CGFloat(sliceArray[index]), y: CGFloat(sliceArray[index + 1])), end: CGPoint(x: CGFloat(sliceArray[index + 2]), y: CGFloat(sliceArray[index + 3]))))
                    }
                }

                // Generic view properties
                ViewletUtil.applyGenericViewAttributes(convUtil: convUtil, view: levelCanvas, attributes: attributes)
                return true
            }
            return false
        }
        
        func canRecycle(convUtil: InflatorConvUtil, object: Any, attributes: [String: Any]) -> Bool {
            return type(of: object) == LevelCanvasView.self
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
    // MARK: Slicing
    // --
    
    func slice(vector: Vector) {
        if let sliced = clipPolygon.sliced(vector: vector) {
            clipPolygon = sliced
            updateMask()
        }
    }

    func resetSlices() {
        clipPolygon = Polygon(points: [ CGPoint(x: 0, y: 0), CGPoint(x: CGFloat(canvasWidth), y: 0), CGPoint(x: CGFloat(canvasWidth), y: CGFloat(canvasHeight)), CGPoint(x: 0, y: CGFloat(canvasHeight)) ])
        updateMask()
    }
    

    // --
    // MARK: Configurable values
    // --
    
    var canvasWidth: Float = 1 {
        didSet {
            if canvasWidth != oldValue {
                clipPolygon = Polygon(points: [ CGPoint(x: 0, y: 0), CGPoint(x: CGFloat(canvasWidth), y: 0), CGPoint(x: CGFloat(canvasWidth), y: CGFloat(canvasHeight)), CGPoint(x: 0, y: CGFloat(canvasHeight)) ])
                updateMask()
            }
        }
    }

    var canvasHeight: Float = 1 {
        didSet {
            if canvasHeight != oldValue {
                clipPolygon = Polygon(points: [ CGPoint(x: 0, y: 0), CGPoint(x: CGFloat(canvasWidth), y: 0), CGPoint(x: CGFloat(canvasWidth), y: CGFloat(canvasHeight)), CGPoint(x: 0, y: CGFloat(canvasHeight)) ])
                updateMask()
            }
        }
    }


    // --
    // MARK: Update mask
    // --
    
    private func updateMask() {
        if let clipPath = clipPolygon.asBezierPath(scaleX: bounds.width / CGFloat(canvasWidth), scaleY: bounds.height / CGFloat(canvasHeight)) {
            let mask = CAShapeLayer()
            mask.path = clipPath.cgPath
            layer.mask = mask
        } else {
            layer.mask = nil
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateMask()
    }

}
