//
//  ControlComponent.swift
//  Component type: a control with interaction, like UIControl
//

import UIKit

protocol ControlComponent: class {

    var isHighlighted: Bool { get set }
    var isEnabled: Bool { get set }

}
