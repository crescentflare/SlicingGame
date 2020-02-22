//
//  InflatorDictBinder.swift
//  Json inflator Pod
//
//  Library binder: object dictionary
//  An inflator binder implementation which contains a dictionary of all referenced objects
//

open class InflatorDictBinder : InflatorBinder {
    
    private var boundObjects = [String: Any]()
    
    public init() {
    }
    
    open func onBind(refId: String, object: Any) {
        boundObjects[refId] = object
    }
    
    open func findByReference(_ refId: String) -> Any? {
        return boundObjects[refId]
    }
    
}
