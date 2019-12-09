//
//  AppDelegate.swift
//  Base application: catches global application events
//

import UIKit
import DynamicAppConfig

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    // --
    // MARK: Window member needed for the global application
    // --
    
    var window: UIWindow?
    
    
    // --
    // MARK: Lifecycle
    // --
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Enable app config utility for non-release builds
        #if !RELEASE
            AppConfigStorage.shared.activate(manager: CustomAppConfigManager.sharedManager)
            AppConfigStorage.shared.addDataObserver(self, selector: #selector(updateConfigurationValues), name: AppConfigStorage.configurationChanged)
            updateConfigurationValues()
        #endif

        // Configure framework
        registerViewlets()
        
        // Launch view controller
        window = CustomWindow(frame: UIScreen.main.bounds)
        window?.backgroundColor = .black
        window?.rootViewController = PageViewController(pageJson: "game.json")
        window?.makeKeyAndVisible()
        return true
    }

    
    // --
    // MARK: App config integration
    // --
    
    @objc func updateConfigurationValues() {
        // No implementation needed (for now)
    }

    
    // --
    // MARK: Inflatable registration
    // --
    
    func registerViewlets() {
        // Enable platform specific attributes
        Inflators.viewlet.setMergeSubAttributes(["ios"])
        Inflators.viewlet.setExcludeAttributes(["android"])

        // Containers
        Inflators.viewlet.register(name: "frameContainer", inflatable: FrameContainerView.viewlet())
        Inflators.viewlet.register(name: "linearContainer", inflatable: LinearContainerView.viewlet())

        // Simple viewlets
        Inflators.viewlet.register(name: "view", inflatable: ViewletUtil.basicViewViewlet())
    }
    
}

fileprivate class CustomWindow: UIWindow {

    override func sendEvent(_ event: UIEvent) {
        super.sendEvent(event)
        if AppConfigStorage.shared.isActivated() && event.subtype == .motionShake {
            AppConfigManageViewController.launch()
        }
    }

}
