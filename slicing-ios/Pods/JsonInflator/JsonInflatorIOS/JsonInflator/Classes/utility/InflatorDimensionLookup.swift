//
//  InflatorDimensionLookup.swift
//  Json inflator Pod
//
//  Library utility: protocol for dimension lookup
//  Integrates with InflatorConvUtil to look up custom dimension sizes or coordinates
//

public protocol InflatorDimensionLookup {
    
    func getDimension(refId: String) -> CGFloat?
    
}
