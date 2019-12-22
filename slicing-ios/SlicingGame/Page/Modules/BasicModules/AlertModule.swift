//
//  AlertModule.swift
//  Basic module: catches alert events to show popups
//

import UIKit

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
                let title = (nextEvent.parameters["title"] as? String) ?? "Alert"
                let text = (nextEvent.parameters["text"] as? String) ?? "No text specified"
                let actionText = (nextEvent.parameters["actionText"] as? String) ?? "OK"
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
