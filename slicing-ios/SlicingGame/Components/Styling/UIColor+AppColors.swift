//
//  UIColor+AppColors.swift
//  Component styling: an extension of UIColor to include the colors used in the app as well as a lookup table
//

import UIKit
import JsonInflator

extension UIColor {

    // --
    // MARK: Color lookup
    // --
    
    class AppColorLookup: InflatorColorLookup {
        
        func getColor(refId: String) -> UIColor? {
            let colorTable: [String: UIColor] = [
                "text": .text,
                
                "red": .red,
                "yellow": .yellow,
                "green": .green,
                "cyan": .cyan,
                "blue": .blue,
                "magenta": .magenta,
                "white": .white,
                "black": .black,
                "transparent": .transparent
            ]
            return colorTable[refId]
        }
        
    }


    // --
    // MARK: Text
    // --

    class var text: UIColor { get { return UIColor(hexValue: 0xff303030) } }


    // --
    // MARK: Duplicate clear into transparent
    // --
    
    class var transparent: UIColor { get { return .clear }}
    
}
