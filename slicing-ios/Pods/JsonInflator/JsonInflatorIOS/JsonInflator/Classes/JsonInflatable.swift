//
//  JsonInflatable.swift
//  Json inflator Pod
//
//  Library: an inflatable object
//  A generic way to create and update an object (with optional recycling)
//  Add an implementation of this to the objects or classes that can be inflated through JSON
//

public protocol JsonInflatable {
    
    func create() -> Any
    @discardableResult func update(convUtil: InflatorConvUtil, object: Any, attributes: [String: Any], parent: Any?, binder: InflatorBinder?) -> Bool
    func canRecycle(convUtil: InflatorConvUtil, object: Any, attributes: [String: Any]) -> Bool
    
}
