package com.crescentflare.slicinggame.infrastructure.coreextensions

import kotlin.math.pow

/**
 * Core extension: extends int to calculate the light intensity of an integer color value
 */
fun Int.colorIntensity(): Double {
    val colorComponents = doubleArrayOf(
        (this and 0xFF).toDouble() / 255.0,
        (this and 0xFF00 shr 8).toDouble() / 255.0,
        (this and 0xFF0000 shr 16).toDouble() / 255.0
    )
    for (i in colorComponents.indices) {
        if (colorComponents[i] <= 0.03928) {
            colorComponents[i] /= 12.92
        }
        colorComponents[i] = ((colorComponents[i] + 0.055) / 1.055).pow(2.4)
    }
    return 0.2126 * colorComponents[0] + 0.7152 * colorComponents[1] + 0.0722 * colorComponents[2]
}
