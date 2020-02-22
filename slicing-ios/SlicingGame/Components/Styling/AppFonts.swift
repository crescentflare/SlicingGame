//
//  AppFonts.swift
//  Component styling: the fonts used in the app, available everywhere
//

import UIKit

class AppFontItem {
    
    var name: String
    
    init(name: String) {
        self.name = name
    }
    
    func font(ofSize: CGFloat) -> UIFont {
        if name == "systemFont" {
            return UIFont.systemFont(ofSize: ofSize)
        } else if name == "italicSystemFont" {
            return UIFont.italicSystemFont(ofSize: ofSize)
        } else if name == "boldSystemFont" {
            return UIFont.boldSystemFont(ofSize: ofSize)
        } else if name == "boldItalicSystemFont" {
            if let descriptor = UIFont.systemFont(ofSize: ofSize).fontDescriptor.withSymbolicTraits([.traitBold, .traitItalic]) {
                return UIFont(descriptor: descriptor, size: ofSize)
            }
            return UIFont.systemFont(ofSize: ofSize)
        }
        if let font = UIFont(name: name, size: ofSize) {
            return font
        }
        return UIFont.systemFont(ofSize: ofSize)
    }
    
}

class AppFonts {
    
    // --
    // MARK: Font lookup
    // --
    
    private static let fontLookup: [String: AppFontItem] = [
        "normal": normal,
        "italics": italics,
        "bold": bold,
        "boldItalics": boldItalics
    ]


    // --
    // MARK: Fonts
    // --
    
    static var normal = AppFontItem(name: "systemFont")
    static var italics = AppFontItem(name: "italicSystemFont")
    static var bold = AppFontItem(name: "boldSystemFont")
    static var boldItalics = AppFontItem(name: "boldItalicSystemFont")

    
    // --
    // MARK: Obtain font through lookup name
    // --
    
    static func font(withName: String, ofSize: CGFloat) -> UIFont {
        if let appFont = fontLookup[withName] {
            return appFont.font(ofSize: ofSize)
        }
        return UIFont.systemFont(ofSize: ofSize)
    }

}
