package com.crescentflare.slicinggame.components.styling

import android.annotation.SuppressLint
import android.content.Context
import android.graphics.Typeface
import androidx.core.content.res.ResourcesCompat

/**
 * Component styling: the fonts used in the app, available everywhere
 * Note: suppress static field leak warning, the context is set through the base application class
 */
@SuppressLint("StaticFieldLeak")
object AppFonts {

    // --
    // Fonts
    // --

    val normal = Font(0, Typeface.NORMAL)
    val italics = Font(0, Typeface.ITALIC)
    val bold = Font(0, Typeface.BOLD)
    val boldItalics = Font(0, Typeface.BOLD_ITALIC)


    // --
    // Font lookup
    // --

    private val fontLookup = mapOf(
        Pair("normal", normal),
        Pair("italics", italics),
        Pair("bold", bold),
        Pair("boldItalics", boldItalics)
    )


    // --
    // Set application context for loading typefaces
    // --

    private var context: Context? = null

    fun setContext(context: Context) {
        this.context = context
    }


    // --
    // Font helper class
    // --

    class Font constructor(private val resource: Int, private val style: Int = Typeface.NORMAL) {

        val typeface: Typeface
            get() {
                // Return cached typeface if it's there
                val checkLoadedTypeface = loadedTypeface
                if (checkLoadedTypeface != null) {
                    return checkLoadedTypeface
                }

                // Load typeface when needed
                val loadContext = context
                if (resource > 0 && loadContext != null) {
                    val typeface = ResourcesCompat.getFont(loadContext, resource)
                    if (typeface != null) {
                        loadedTypeface = typeface
                        return typeface
                    }
                }

                // Return default typeface
                val defaultTypeface = Typeface.create(Typeface.DEFAULT, style)
                loadedTypeface = defaultTypeface
                return defaultTypeface
            }

        private var loadedTypeface: Typeface? = null

    }


    // --
    // Get a typeface
    // --

    fun getTypeface(fontName: String?): Typeface {
        if (fontName != null) {
            fontLookup[fontName]?.let {
                return it.typeface
            }
        }
        return normal.typeface
    }

}
