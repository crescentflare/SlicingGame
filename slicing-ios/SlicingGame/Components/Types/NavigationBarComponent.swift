//
//  NavigationBarComponent.swift
//  Component type: navigation bar components should implement this
//

import UIKit

protocol NavigationBarComponent: class {

    var averageColor: UIColor? { get }
    var statusBarHeight: CGFloat { get set }
    var barContentHeight: CGFloat { get set }

}
