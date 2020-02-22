//
//  String+URLCoding.swift
//  Core extension: extends string support for URL encoding or decoding
//

import Foundation

extension String {
    
    func urlEncode() -> String {
        let characters = (CharacterSet.urlQueryAllowed as NSCharacterSet).mutableCopy() as! NSMutableCharacterSet
        characters.removeCharacters(in: "!*'();:@&=+$,/?%#[]")
        characters.addCharacters(in: " ")
        guard let encodedString = addingPercentEncoding(withAllowedCharacters: characters as CharacterSet) else {
            return self
        }
        return encodedString.replacingOccurrences(of: " ", with: "+")
    }

    func urlDecode() -> String {
        let result = replacingOccurrences(of: "+", with: " ")
        return result.removingPercentEncoding ?? result
    }
    
}
