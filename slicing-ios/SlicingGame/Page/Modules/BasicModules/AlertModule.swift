//
//  AlertModule.swift
//  Basic module: catches alert events to show popups
//

import UIKit
import JsonInflator

class AlertModule: PageModule {
    
    // --
    // MARK: Show alert popups
    // --
    
    class func showSimpleAlert(viewController: UIViewController?, title: String, text: String, actionText: String, completion: (() -> Void)? = nil) {
        let alertController = UIAlertController(title: title, message: text, preferredStyle: .alert)
        let okAction = UIAlertAction(title: actionText, style: .default) { (action: UIAlertAction) in
            completion?()
        }
        alertController.addAction(okAction)
        viewController?.present(alertController, animated: true, completion: nil)
    }


    // --
    // MARK: Members
    // --
    
    let handleEventTypes = ["alert"]
    private weak var viewController: PageViewController?
    private var queuedEvents = [AppEvent]()
    private var paused = true
    private var alertShown = false

    
    // --
    // MARK: Inflator integration
    // --
    
    class func inflatable() -> JsonInflatable {
        return InflatorClass()
    }
    
    private class InflatorClass: JsonInflatable {
        
        func create() -> Any {
            return AlertModule()
        }
        
        func update(convUtil: InflatorConvUtil, object: Any, attributes: [String: Any], parent: Any?, binder: InflatorBinder?) -> Bool {
            return object is AlertModule
        }
        
        func canRecycle(convUtil: InflatorConvUtil, object: Any, attributes: [String: Any]) -> Bool {
            return type(of: object) == AlertModule.self
        }
        
    }


    // --
    // MARK: Initialization
    // --
    
    init() {
        // No implementation
    }


    // --
    // MARK: Lifecycle
    // --

    func didCreate(viewController: PageViewController) {
        self.viewController = viewController
    }
    
    func didResume() {
        paused = false
        tryHandleQueuedEvent()
    }
    
    func didPause() {
        paused = true
    }
    
    func willDestroy() {
        // No implementation
    }
    

    // --
    // MARK: Event handling
    // --

    func handleEvent(_ event: AppEvent, sender: Any?) -> Bool {
        if event.type == "alert" {
            queuedEvents.append(event)
            tryHandleQueuedEvent()
            return true
        }
        return false
    }
    
    private func tryHandleQueuedEvent() {
        if !paused && !alertShown {
            if let nextEvent = queuedEvents.first {
                let title = (nextEvent.parameters["localizedTitle"] as? String)?.localized() ?? (nextEvent.parameters["title"] as? String) ?? "ALERT_UNSPECIFIED_TITLE".localized()
                let text = (nextEvent.parameters["localizedText"] as? String)?.localized() ?? (nextEvent.parameters["text"] as? String) ?? "ALERT_UNSPECIFIED_TEXT".localized()
                let actionText = (nextEvent.parameters["localizedActionText"] as? String)?.localized() ?? (nextEvent.parameters["actionText"] as? String) ?? "ALERT_OK".localized()
                queuedEvents.removeFirst()
                alertShown = true
                AlertModule.showSimpleAlert(viewController: viewController, title: title, text: text, actionText: actionText, completion: {
                    self.alertShown = false
                    self.tryHandleQueuedEvent()
                })
            }
        }
    }

}
