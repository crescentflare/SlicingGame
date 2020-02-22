//
//  CustomAppConfigManager.swift
//  App config integration: manager class to facilitate app config selection and model definition
//

import UIKit
import DynamicAppConfig

class CustomAppConfigManager: AppConfigBaseManager {

    // --
    // MARK: Singleton instance
    // --
    
    static let sharedManager: CustomAppConfigManager = CustomAppConfigManager()

    
    // --
    // MARK: Methods
    // --
    
    override func obtainBaseModelInstance() -> AppConfigBaseModel {
        return CustomAppConfigModel()
    }
    
    static func currentConfig() -> CustomAppConfigModel {
        return sharedManager.currentConfigInstance() as! CustomAppConfigModel
    }

}
