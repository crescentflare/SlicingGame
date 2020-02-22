package com.crescentflare.slicinggame.infrastructure.appconfig

/**
 * App config: enum for page loading mode
 */
enum class AppConfigPageLoadingMode(val value: String) {

    Local("local"),
    Server("server");

    companion object {

        fun fromString(string: String?): AppConfigPageLoadingMode {
            for (enum in values()) {
                if (enum.value == string) {
                    return enum
                }
            }
            return Local
        }

    }

}
