//
//  PageModule.swift
//  Page module: provides a protocol for separating controller logic into modules
//

protocol PageModule: class {
    
    var handleEventTypes: [String] { get }
    
    func didCreate(viewController: PageViewController)
    func didResume()
    func didPause()
    func willDestroy()

    func handleEvent(_ event: AppEvent, sender: Any?) -> Bool

}
