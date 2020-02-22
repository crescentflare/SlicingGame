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
                
                "slicePreviewLine": slicePreviewLine,
                "stretchedSlicePreviewLine": stretchedSlicePreviewLine,
                
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
    // MARK: Game
    // --

    class var slicePreviewLine: UIColor { get { return UIColor(hexValue: 0xffff0000) } }
    class var stretchedSlicePreviewLine: UIColor { get { return UIColor(hexValue: 0x40ff0000) } }


    // --
    // MARK: Duplicate clear into transparent
    // --
    
    class var transparent: UIColor { get { return .clear }}
    
}
