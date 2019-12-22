//
//  ComponentStateImage.swift
//  Component utility: handles images for component states
//

import UIKit

class ComponentStateImage {
    
    // --
    // MARK: Members
    // --

    var image: UIImage? {
        didSet {
            if image !== oldValue {
                updateImage()
            }
        }
    }
    
    var highlightedImage: UIImage? {
        didSet {
            if highlightedImage !== oldValue {
                updateImage()
            }
        }
    }
    
    var disabledImage: UIImage? {
        didSet {
            if disabledImage !== oldValue {
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

    private var activeStateImage: UIImage?
    

    // --
    // MARK: State handling
    // --
    
    func currentImage() -> UIImage? {
        return activeStateImage
    }
    
    private func updateImage() {
        switch state {
        case .disabled:
            activeStateImage = disabledImage ?? image
        case .highlighted:
            activeStateImage = highlightedImage ?? image
        default:
            activeStateImage = image
        }
    }

}
