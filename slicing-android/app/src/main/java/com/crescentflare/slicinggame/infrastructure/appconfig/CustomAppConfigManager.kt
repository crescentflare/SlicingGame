package com.crescentflare.slicinggame.infrastructure.appconfig

import com.crescentflare.dynamicappconfig.manager.AppConfigBaseManager
import com.crescentflare.dynamicappconfig.model.AppConfigBaseModel

/**
 * App config: custom configuration manager
 */
class CustomAppConfigManager : AppConfigBaseManager() {

    // --
    // Static: singleton access
    // --

    companion object {

        var instance = CustomAppConfigManager()

        fun currentConfig(): CustomAppConfigModel {
            return instance.forcedConfigModel ?: instance.currentConfigInstance as CustomAppConfigModel
        }

    }


    // --
    // Member
    // --

    private var forcedConfigModel: CustomAppConfigModel? = null


    // --
    // Implementation
    // --

    override fun getBaseModelInstance(): AppConfigBaseModel {
        return CustomAppConfigModel()
    }

    fun setForcedConfigModel(model: CustomAppConfigModel) {
        forcedConfigModel = model
    }

}
