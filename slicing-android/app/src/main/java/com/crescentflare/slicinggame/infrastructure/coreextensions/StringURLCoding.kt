package com.crescentflare.slicinggame.infrastructure.coreextensions

import java.net.URLDecoder
import java.net.URLEncoder

/**
 * Core extension: extends string to add support for URL encoding or decoding
 */
fun String.urlEncode(): String {
    return URLEncoder.encode(this, "UTF-8")
}

fun String.urlDecode(): String {
    return URLDecoder.decode(this, "UTF-8")
}
