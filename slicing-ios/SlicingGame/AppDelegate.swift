//
//  AppDelegate.swift
//  Base application: catches global application events
//

import UIKit

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
        // Configure framework
        registerViewlets()
        
        // Launch view controller
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.backgroundColor = .black
        window?.rootViewController = PageViewController()
        window?.makeKeyAndVisible()
        return true
    }

    
    // --
    // MARK: Inflatable registration
    // --
    
    func registerViewlets() {
        // Enable platform specific attributes
        Inflators.viewlet.setMergeSubAttributes(["ios"])
        Inflators.viewlet.setExcludeAttributes(["android"])

        // Simple viewlets
        Inflators.viewlet.register(name: "view", inflatable: ViewletUtil.basicViewViewlet())
    }
    
}
