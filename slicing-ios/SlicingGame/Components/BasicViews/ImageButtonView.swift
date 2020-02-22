//
//  ImageButtonView.swift
//  Basic view: an image which can be used as a button
//

import UIKit
import UniLayout
import JsonInflator

class ImageButtonView: UniImageView, ControlComponent {
    
    // --
    // MARK: Members
    // --
    
    var isEnabled: Bool {
        set {
            isUserInteractionEnabled = newValue
        }
        get { return isUserInteractionEnabled }
    }

    var isHighlighted = false {
        didSet {
            updateState()
        }
    }

    private let touchInsideTolerance: CGFloat = 64
    private var stateImage = ComponentStateImage()

    
    // --
    // MARK: Viewlet integration
    // --

    class func viewlet() -> JsonInflatable {
        return ViewletClass()
    }
    
    private class ViewletClass: JsonInflatable {
        
        func create() -> Any {
            return ImageButtonView()
        }
        
        func update(convUtil: InflatorConvUtil, object: Any, attributes: [String: Any], parent: Any?, binder: InflatorBinder?) -> Bool {
            if let imageButton = object as? ImageButtonView {
                // Apply images
                let stretchType = ImageStretchType(rawValue: convUtil.asString(value: attributes["stretchType"]) ?? "") ?? .none
                imageButton.internalImageView.contentMode = stretchType.toContentMode()
                imageButton.source = ImageSource.fromValue(value: attributes["source"])
                imageButton.highlightedSource = ImageSource.fromValue(value: attributes["highlightedSource"])
                imageButton.disabledSource = ImageSource.fromValue(value: attributes["disabledSource"])
                
                // Apply colorization
                imageButton.colorize = convUtil.asColor(value: attributes["colorize"])
                imageButton.highlightedColorize = convUtil.asColor(value: attributes["highlightedColorize"])
                imageButton.disabledColorize = convUtil.asColor(value: attributes["disabledColorize"])

                // Generic view properties
                ViewletUtil.applyGenericViewAttributes(convUtil: convUtil, view: imageButton, attributes: attributes)

                // Apply event
                imageButton.tapEvent = AppEvent.fromValue(value: attributes["tapEvent"])

                // Chain event observer
                if let eventObserver = parent as? AppEventObserver {
                    imageButton.eventObserver = eventObserver
                }
                return true
            }
            return false
        }
        
        func canRecycle(convUtil: InflatorConvUtil, object: Any, attributes: [String: Any]) -> Bool {
            return type(of: object) == ImageButtonView.self
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
        clipsToBounds = true
        isUserInteractionEnabled = false
        tintAdjustmentMode = .normal
        internalImageView.contentMode = .center
    }
    
    
    // --
    // MARK: Configurable values
    // --
    
    weak var eventObserver: AppEventObserver?
    
    var tapEvent: AppEvent? {
        didSet {
            isEnabled = tapEvent != nil
        }
    }

    var source: ImageSource? {
        didSet {
            if source !== oldValue {
                if let source = source {
                    source.getImage(completion: { [weak self] image in
                        if self?.source === source {
                            self?.stateImage.image = image
                            self?.updateState()
                        }
                    })
                } else {
                    stateImage.image = nil
                    updateState()
                }
            }
        }
    }

    var highlightedSource: ImageSource? {
        didSet {
            if highlightedSource !== oldValue {
                if let highlightedSource = highlightedSource {
                    highlightedSource.getImage(completion: { [weak self] image in
                        if self?.highlightedSource === highlightedSource {
                            self?.stateImage.highlightedImage = image
                            self?.updateState()
                        }
                    })
                } else {
                    stateImage.highlightedImage = nil
                    updateState()
                }
            }
        }
    }

    var disabledSource: ImageSource? {
        didSet {
            if disabledSource !== oldValue {
                if let disabledSource = disabledSource {
                    disabledSource.getImage(completion: { [weak self] image in
                        if self?.disabledSource === disabledSource {
                            self?.stateImage.disabledImage = image
                            self?.updateState()
                        }
                    })
                } else {
                    stateImage.disabledImage = nil
                    updateState()
                }
            }
        }
    }
    
    var colorize: UIColor? {
        set {
            stateImage.colorize = newValue
            updateState()
        }
        get { return stateImage.colorize }
    }

    var highlightedColorize: UIColor? {
        set {
            stateImage.highlightedColorize = newValue
            updateState()
        }
        get { return stateImage.highlightedColorize }
    }

    var disabledColorize: UIColor? {
        set {
            stateImage.disabledColorize = newValue
            updateState()
        }
        get { return stateImage.disabledColorize }
    }

    
    // --
    // MARK: Interaction
    // --

    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let _ = touches.first {
            isHighlighted = true
            return
        }
        super.touchesBegan(touches, with: event)
    }
    
    open override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let position = touch.location(in: self)
            isHighlighted = position.x >= -touchInsideTolerance && position.x < frame.width + touchInsideTolerance && position.y >= -touchInsideTolerance && position.y < frame.height + touchInsideTolerance
            return
        }
        super.touchesMoved(touches, with: event)
    }

    open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            isHighlighted = false
            let position = touch.location(in: self)
            if position.x >= -touchInsideTolerance && position.x < frame.width + touchInsideTolerance && position.y >= -touchInsideTolerance && position.y < frame.height + touchInsideTolerance {
                buttonTapped()
            }
            return
        }
        super.touchesEnded(touches, with: event)
    }
    
    private func buttonTapped() {
        if let tapEvent = tapEvent {
            eventObserver?.observedEvent(tapEvent, sender: self)
        }
    }

    
    // --
    // MARK: State handling
    // --
    
    override var isUserInteractionEnabled: Bool {
        didSet {
            updateState()
        }
    }
    
    private func updateState() {
        if isEnabled {
            stateImage.state = isHighlighted ? .highlighted : .normal
        } else {
            stateImage.state = .disabled
        }
        image = stateImage.currentImage()
        internalImageView.tintColor = stateImage.currentColorize()
    }
    
}
