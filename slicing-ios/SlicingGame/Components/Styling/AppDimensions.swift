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
                "pagePadding": pagePadding,

                "text": text,
                "titleText": titleText,
                
                "slicePreviewDot": slicePreviewDot,
                "slicePreviewWidth": slicePreviewWidth,
                "slicePreviewDash": slicePreviewDash,
                
                "portraitTitleBarHeight": portraitTitleBarHeight,
                "landscapeTitleBarHeight": landscapeTitleBarHeight
            ]
            return dimensionTable[refId]
        }
        
    }
    
    
    // --
    // MARK: Margins
    // --
    
    class var pagePadding: CGFloat { get { return 8 }}


    // --
    // MARK: Text
    // --
    
    class var text: CGFloat { get { return 17 } }
    class var titleText: CGFloat { get { return 20 } }
    
    
    // --
    // MARK: Game
    // --
    
    class var slicePreviewDot: CGFloat { get { return 10 } }
    class var slicePreviewWidth: CGFloat { get { return 2 } }
    class var slicePreviewDash: CGFloat { get { return 8 } }


    // --
    // MARK: UIKit component sizes
    // --

    class var portraitTitleBarHeight: CGFloat { get { return 44 } }
    class var landscapeTitleBarHeight: CGFloat { get { return 32 } }

}
