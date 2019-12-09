//
//  AppDimensions.swift
//  Component styling: the dimensions used in the app, available everywhere
//

import UIKit
import JsonInflator

class AppDimensions {
    
    // --
    // MARK: Dimension lookup
    // --
    
    class AppDimensionLookup: InflatorDimensionLookup {
        
        func getDimension(refId: String) -> CGFloat? {
            let dimensionTable: [String: CGFloat] = [
                "text": text,
                "titleText": titleText
            ]
            return dimensionTable[refId]
        }
        
    }
    
    
    // --
    // MARK: Text
    // --
    
    class var text: CGFloat { get { return 17 } }
    class var titleText: CGFloat { get { return 20 } }

}
