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
        registerModules()
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
    
    func registerModules() {
        // Enable platform specific attributes
        Inflators.viewlet.setMergeSubAttributes(["ios"])
        Inflators.viewlet.setExcludeAttributes(["android"])

        // Basic modules
        Inflators.module.register(name: "alert", inflatable: AlertModule.inflatable())
        Inflators.module.register(name: "vibrate", inflatable: VibrateModule.inflatable())

        // Custom modules
        Inflators.module.register(name: "game", inflatable: GameModule.inflatable())
    }

    func registerViewlets() {
        // Enable platform specific attributes
        Inflators.viewlet.setMergeSubAttributes(["ios"])
        Inflators.viewlet.setExcludeAttributes(["android"])

        // Lookups
        Inflators.viewlet.colorLookup = UIColor.AppColorLookup()
        Inflators.viewlet.dimensionLookup = AppDimensions.AppDimensionLookup()

        // Basic views
        Inflators.viewlet.register(name: "image", inflatable: ImageView.viewlet())
        Inflators.viewlet.register(name: "imageButton", inflatable: ImageButtonView.viewlet())
        Inflators.viewlet.register(name: "text", inflatable: TextView.viewlet())
        Inflators.viewlet.register(name: "view", inflatable: ViewletUtil.basicViewViewlet())

        // Containers
        Inflators.viewlet.register(name: "frameContainer", inflatable: FrameContainerView.viewlet())
        Inflators.viewlet.register(name: "gameContainer", inflatable: GameContainerView.viewlet())
        Inflators.viewlet.register(name: "linearContainer", inflatable: LinearContainerView.viewlet())
        Inflators.viewlet.register(name: "pageContainer", inflatable: PageContainerView.viewlet())
        Inflators.viewlet.register(name: "spriteContainer", inflatable: SpriteContainerView.viewlet())

        // Game
        Inflators.viewlet.register(name: "level", inflatable: LevelView.viewlet())
        Inflators.viewlet.register(name: "levelCanvas", inflatable: LevelCanvasView.viewlet())
        Inflators.viewlet.register(name: "levelSlicePreview", inflatable: LevelSlicePreviewView.viewlet())

        // Navigation bars
        Inflators.viewlet.register(name: "gameTitleBar", inflatable: GameTitleBarView.viewlet())
        Inflators.viewlet.register(name: "simpleBottomBar", inflatable: SimpleBottomBarView.viewlet())
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
