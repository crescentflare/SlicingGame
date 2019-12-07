//
//  InflatorColorLookup.swift
//  Json inflator Pod
//
//  Library utility: protocol for color lookup
//  Integrates with InflatorConvUtil to look up custom color references
//

public protocol InflatorColorLookup {
    
    func getColor(refId: String) -> UIColor?
    
}
