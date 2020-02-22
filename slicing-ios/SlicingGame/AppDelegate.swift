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
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.backgroundColor = .black
        window?.rootViewController = PageViewController()
        window?.makeKeyAndVisible()
        return true
    }

}
