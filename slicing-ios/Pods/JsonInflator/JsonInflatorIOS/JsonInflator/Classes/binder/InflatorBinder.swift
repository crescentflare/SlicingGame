//
//  InflatorBinder.swift
//  Json inflator Pod
//
//  Library binder: default protocol
//  A protocol which can be implemented to do custom binding of objects during JSON inflation
//

public protocol InflatorBinder {
    
    func onBind(refId: String, object: Any)
    
}
