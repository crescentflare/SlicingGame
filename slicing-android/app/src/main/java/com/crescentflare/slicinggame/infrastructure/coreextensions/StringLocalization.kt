package com.crescentflare.slicinggame.infrastructure.coreextensions

import android.content.Context
import java.util.*

/**
 * Core extension: extends string to look up the localized entry in the strings.xml file
 */
fun String.localized(context: Context): String {
    val key = this.toLowerCase(Locale.getDefault())
    val id = context.resources.getIdentifier(key, "string", context.packageName)
    return if (id > 0) context.resources.getString(id) else this
}
