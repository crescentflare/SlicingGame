//
//  UIColor+HexValue.swift
//  Core extension: create a UIColor instance from a hexadecimal value
//

import UIKit

extension UIColor {
    
    convenience init(hexValue: UInt) {
        let alpha = CGFloat((hexValue & 0xff000000) >> 24) / 255
        let red = CGFloat((hexValue & 0xff0000) >> 16) / 255
        let green = CGFloat((hexValue & 0xff00) >> 8) / 255
        let blue = CGFloat(hexValue & 0xff) / 255
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }

}
