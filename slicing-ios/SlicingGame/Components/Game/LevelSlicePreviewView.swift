//
//  LevelSlicePreviewView.swift
//  Game view: shows a helper line for previewing a slice
//

import UIKit
import UniLayout
import JsonInflator

class LevelSlicePreviewView: UniView {
    
    // --
    // MARK: Members
    // --
    
    private var sliceVector: Vector?
    

    // --
    // MARK: Viewlet integration
    // --

    class func viewlet() -> JsonInflatable {
        return ViewletClass()
    }
    
    private class ViewletClass: JsonInflatable {
        
        func create() -> Any {
            return LevelSlicePreviewView()
        }
        
        func update(convUtil: InflatorConvUtil, object: Any, attributes: [String: Any], parent: Any?, binder: InflatorBinder?) -> Bool {
            if let slicePreview = object as? LevelSlicePreviewView {
                // Apply start position
                let startPositionArray = convUtil.asDimensionArray(value: attributes["start"])
                if startPositionArray.count == 2 {
                    slicePreview.start = CGPoint(x: startPositionArray[0], y: startPositionArray[1])
                } else {
                    slicePreview.start = nil
                }

                // Apply end position
                let endPositionArray = convUtil.asDimensionArray(value: attributes["end"])
                if endPositionArray.count == 2 {
                    slicePreview.end = CGPoint(x: endPositionArray[0], y: endPositionArray[1])
                } else {
                    slicePreview.end = nil
                }
                
                // Apply colors
                slicePreview.color = convUtil.asColor(value: attributes["color"])
                slicePreview.stretchedColor = convUtil.asColor(value: attributes["stretchedColor"])

                // Generic view properties
                ViewletUtil.applyGenericViewAttributes(convUtil: convUtil, view: slicePreview, attributes: attributes)
                return true
            }
            return false
        }
        
        func canRecycle(convUtil: InflatorConvUtil, object: Any, attributes: [String: Any]) -> Bool {
            return type(of: object) == LevelSlicePreviewView.self
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
    // MARK: Configurable values
    // --
    
    var start: CGPoint? {
        didSet {
            if start != oldValue {
                if let start = start, let end = end {
                    sliceVector = Vector(start: start, end: end)
                } else {
                    sliceVector = nil
                }
                updateLayers()
            }
        }
    }

    var end: CGPoint? {
        didSet {
            if end != oldValue {
                if let start = start, let end = end {
                    sliceVector = Vector(start: start, end: end)
                } else {
                    sliceVector = nil
                }
                updateLayers()
            }
        }
    }
    
    var color: UIColor? {
        didSet {
            updateLayers()
        }
    }

    var stretchedColor: UIColor? {
        didSet {
            updateLayers()
        }
    }

    
    // --
    // MARK: Update layers
    // --
    
    private func updateLayers() {
        // Clear sublayers
        for layer in layer.sublayers ?? [] {
            layer.removeFromSuperlayer()
        }

        // Add stretched line to component edges
        if let sliceVector = sliceVector, sliceVector.isValid() {
            let stretchedVector = sliceVector.stretchedToEdges(topLeft: CGPoint(x: 0, y: 0), bottomRight: CGPoint(x: bounds.width, y: bounds.height))
            if stretchedVector.isValid() {
                let stretchedLine = CAShapeLayer()
                let stretchedLinePath = UIBezierPath()
                stretchedLinePath.move(to: stretchedVector.start)
                stretchedLinePath.addLine(to: stretchedVector.end)
                stretchedLine.path = stretchedLinePath.cgPath
                stretchedLine.strokeColor = stretchedColor?.cgColor
                stretchedLine.lineWidth = AppDimensions.slicePreviewStretchedWidth
                layer.addSublayer(stretchedLine)
            }
        }
        
        // Add start/end dots
        let dotOffset = AppDimensions.slicePreviewDot / 2
        if let start = start {
            let startDot = CAShapeLayer()
            startDot.path = UIBezierPath(ovalIn: CGRect(x: start.x - dotOffset, y: start.y - dotOffset, width: AppDimensions.slicePreviewDot, height: AppDimensions.slicePreviewDot)).cgPath
            startDot.fillColor = color?.cgColor
            layer.addSublayer(startDot)
        }
        if let end = end {
            let endDot = CAShapeLayer()
            endDot.path = UIBezierPath(ovalIn: CGRect(x: end.x - dotOffset, y: end.y - dotOffset, width: AppDimensions.slicePreviewDot, height: AppDimensions.slicePreviewDot)).cgPath
            endDot.fillColor = color?.cgColor
            layer.addSublayer(endDot)
        }
        
        // Add line
        if let sliceVector = sliceVector, sliceVector.isValid() {
            let line = CAShapeLayer()
            let linePath = UIBezierPath()
            let dash = NSNumber(value: Float(AppDimensions.slicePreviewDash))
            linePath.move(to: sliceVector.start)
            linePath.addLine(to: sliceVector.end)
            line.path = linePath.cgPath
            line.strokeColor = color?.cgColor
            line.lineWidth = AppDimensions.slicePreviewWidth
            line.lineDashPattern = [dash, dash]
            layer.addSublayer(line)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateLayers()
    }

}
