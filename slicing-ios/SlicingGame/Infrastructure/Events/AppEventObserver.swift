//
//  AppEventObserver.swift
//  Event system: a protocol to observe for events
//

protocol AppEventObserver: class {
    
    func observedEvent(_ event: AppEvent, sender: Any?)
    
}
