//
//  ComponentStateImage.swift
//  Component utility: handles images for component states and colorization
//

import UIKit

class ComponentStateImage {
    
    // --
    // MARK: Members
    // --

    var image: UIImage? {
        didSet {
            if image !== oldValue {
                templateImage = nil
                updateImage()
            }
        }
    }
    
    var highlightedImage: UIImage? {
        didSet {
            if highlightedImage !== oldValue {
                templateHighlightedImage = nil
                updateImage()
            }
        }
    }
    
    var disabledImage: UIImage? {
        didSet {
            if disabledImage !== oldValue {
                templateDisabledImage = nil
                updateImage()
            }
        }
    }
    
    var colorize: UIColor? {
        didSet {
            if colorize !== oldValue {
                updateImage()
            }
        }
    }
    
    var highlightedColorize: UIColor? {
        didSet {
            if highlightedColorize !== oldValue {
                updateImage()
            }
        }
    }
    
    var disabledColorize: UIColor? {
        didSet {
            if disabledColorize !== oldValue {
                updateImage()
            }
        }
    }

    var state = UIControl.State.normal {
        didSet {
            if state != oldValue {
                updateImage()
            }
        }
    }

    private var templateImage: UIImage?
    private var templateHighlightedImage: UIImage?
    private var templateDisabledImage: UIImage?
    private var activeStateImage: UIImage?
    private var activeStateColorize: UIColor?
    

    // --
    // MARK: State handling
    // --
    
    func currentImage() -> UIImage? {
        return activeStateImage
    }
    
    func currentColorize() -> UIColor? {
        return activeStateColorize
    }
    
    private func updateImage() {
        switch state {
        case .disabled:
            activeStateColorize = disabledColorize ?? colorize
            if activeStateColorize != nil {
                if let disabledImage = disabledImage {
                    if templateDisabledImage == nil {
                        templateDisabledImage = disabledImage.withRenderingMode(.alwaysTemplate)
                    }
                } else if let image = image, templateImage == nil {
                    templateImage = image.withRenderingMode(.alwaysTemplate)
                }
                activeStateImage = templateDisabledImage ?? templateImage
            } else {
                activeStateImage = disabledImage ?? image
            }
        case .highlighted:
            activeStateColorize = highlightedColorize ?? colorize
            if activeStateColorize != nil {
                if let highlightedImage = highlightedImage {
                    if templateHighlightedImage == nil {
                        templateHighlightedImage = highlightedImage.withRenderingMode(.alwaysTemplate)
                    }
                } else if let image = image, templateImage == nil {
                    templateImage = image.withRenderingMode(.alwaysTemplate)
                }
                activeStateImage = templateHighlightedImage ?? templateImage
            } else {
                activeStateImage = highlightedImage ?? image
            }
        default:
            activeStateColorize = colorize
            if activeStateColorize != nil {
                if let image = image, templateImage == nil {
                    templateImage = image.withRenderingMode(.alwaysTemplate)
                }
                activeStateImage = templateImage
            } else {
                activeStateImage = image
            }
        }
    }
    
}
