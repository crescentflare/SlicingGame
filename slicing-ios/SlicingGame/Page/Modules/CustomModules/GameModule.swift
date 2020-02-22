//
//  AlertModule.swift
//  Custom module: handles custom logic on the game page
//

import UIKit
import JsonInflator

class GameModule: PageModule {
    
    // --
    // MARK: Members
    // --
    
    let handleEventTypes = ["game"]
    private var currentBackground = 0
    private var shuffledBackgrounds = [ImageSource]()

    
    // --
    // MARK: Inflator integration
    // --
    
    class func inflatable() -> JsonInflatable {
        return InflatorClass()
    }
    
    private class InflatorClass: JsonInflatable {
        
        func create() -> Any {
            return GameModule()
        }
        
        func update(convUtil: InflatorConvUtil, object: Any, attributes: [String: Any], parent: Any?, binder: InflatorBinder?) -> Bool {
            if let gameModule = object as? GameModule {
                // Apply component reference
                let layoutBinder = (parent as? PageViewController)?.binder
                let component = layoutBinder?.findByReference(convUtil.asString(value: attributes["gameContainer"]) ?? "")
                gameModule.gameContainer = component as? GameContainerView
                
                // Apply random backgrounds
                var randomBackgrounds = [ImageSource]()
                for randomBackground in attributes["randomBackgrounds"] as? [Any] ?? [] {
                    if let image = ImageSource.fromValue(value: randomBackground) {
                        randomBackgrounds.append(image)
                    }
                }
                gameModule.randomBackgrounds = randomBackgrounds
                return true
            }
            return false
        }
        
        func canRecycle(convUtil: InflatorConvUtil, object: Any, attributes: [String: Any]) -> Bool {
            return type(of: object) == GameModule.self
        }
        
    }


    // --
    // MARK: Initialization
    // --
    
    init() {
        // No implementation
    }


    // --
    // MARK: Configurable values
    // --
    
    var gameContainer: GameContainerView? {
        didSet {
            if gameContainer != oldValue && currentBackground < shuffledBackgrounds.count {
                gameContainer?.backgroundImage = shuffledBackgrounds[currentBackground]
            }
        }
    }
    
    var randomBackgrounds = [ImageSource]() {
        didSet {
            if randomBackgrounds != oldValue && randomBackgrounds.count > 0 {
                currentBackground = 0
                shuffledBackgrounds = randomBackgrounds.shuffled()
                gameContainer?.backgroundImage = shuffledBackgrounds[currentBackground]
            }
        }
    }


    // --
    // MARK: Lifecycle
    // --

    func didCreate(viewController: PageViewController) {
        // No implementation
    }
    
    func didResume() {
        // No implementation
    }
    
    func didPause() {
        // No implementation
    }
    
    func willDestroy() {
        // No implementation
    }
    

    // --
    // MARK: Event handling
    // --

    func handleEvent(_ event: AppEvent, sender: Any?) -> Bool {
        if event.type == "game" {
            switch event.name {
            case "reset":
                gameContainer?.resetSlices()
                if shuffledBackgrounds.count > 0 {
                    currentBackground = (currentBackground + 1) % shuffledBackgrounds.count
                    gameContainer?.backgroundImage = shuffledBackgrounds[currentBackground]
                }
            default:
                break
            }
            return true
        }
        return false
    }

}
