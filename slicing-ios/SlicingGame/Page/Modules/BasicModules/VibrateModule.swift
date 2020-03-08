//
//  VibrateModule.swift
//  Basic module: catches events to vibrate the device
//

import UIKit
import JsonInflator
import AudioToolbox

class VibrateModule: PageModule {
    
    // --
    // MARK: Vibrate
    // --
    
    enum VibrateImpact {
        
        case light
        case normal
        case heavy
        
    }
    
    class func vibrate(impact: VibrateImpact) {
        if #available(iOS 10.0, *) {
            let style: UIImpactFeedbackGenerator.FeedbackStyle
            switch impact {
            case .light:
                style = .light
            case .normal:
                style = .medium
            case .heavy:
                style = .heavy
            }
            UIImpactFeedbackGenerator(style: style).impactOccurred()
        } else {
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        }
    }


    // --
    // MARK: Members
    // --
    
    let handleEventTypes = ["vibrate"]

    
    // --
    // MARK: Inflator integration
    // --
    
    class func inflatable() -> JsonInflatable {
        return InflatorClass()
    }
    
    private class InflatorClass: JsonInflatable {
        
        func create() -> Any {
            return VibrateModule()
        }
        
        func update(convUtil: InflatorConvUtil, object: Any, attributes: [String: Any], parent: Any?, binder: InflatorBinder?) -> Bool {
            return object is VibrateModule
        }
        
        func canRecycle(convUtil: InflatorConvUtil, object: Any, attributes: [String: Any]) -> Bool {
            return type(of: object) == VibrateModule.self
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
        if event.type == "vibrate" {
            VibrateModule.vibrate(impact: .light)
            return true
        }
        return false
    }

}
