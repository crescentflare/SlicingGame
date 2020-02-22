//
//  UIColor+Intensity.swift
//  Core extension: extends color to calculate light intensity
//

import UIKit

extension UIColor {

    func intensity() -> Double {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        if getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
            var colorComponents: [Double] = [Double(blue), Double(green), Double(red)]
            for i in colorComponents.indices {
                if colorComponents[i] <= 0.03928 {
                    colorComponents[i] /= 12.92
                }
                colorComponents[i] = pow((colorComponents[i] + 0.055) / 1.055, 2.4)
            }
            return 0.2126 * colorComponents[0] + 0.7152 * colorComponents[1] + 0.0722 * colorComponents[2]
        }
        return 0
    }

}
