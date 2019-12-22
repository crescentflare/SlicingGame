package com.crescentflare.slicinggame.components.utility

import android.graphics.*
import android.graphics.drawable.Drawable


/**
 * Component utility: a flexible drawable container for component states and colorization
 */
class ComponentStateDrawable : Drawable() {

    // --
    // Members
    // --

    var drawable: Drawable? = null
        set(drawable) {
            if (field !== drawable) {
                field = drawable
                colorizeDrawable = null
                onStateChange(state)
            }
        }

    var pressedDrawable: Drawable? = null
        set(drawable) {
            if (field !== drawable) {
                field = drawable
                colorizePressedDrawable = null
                onStateChange(state)
            }
        }

    var disabledDrawable: Drawable? = null
        set(drawable) {
            if (field !== drawable) {
                field = drawable
                colorizeDisabledDrawable = null
                onStateChange(state)
            }
        }

    var colorize: Int? = null
        set(colorize) {
            if (field != colorize) {
                field = colorize
                onStateChange(state)
            }
        }

    var pressedColorize: Int? = null
        set(pressedColorize) {
            if (field != pressedColorize) {
                field = pressedColorize
                onStateChange(state)
            }
        }

    var disabledColorize: Int? = null
        set(disabledColorize) {
            if (field != disabledColorize) {
                field = disabledColorize
                onStateChange(state)
            }
        }

    private var colorizeDrawable: Drawable? = null
    private var colorizePressedDrawable: Drawable? = null
    private var colorizeDisabledDrawable: Drawable? = null
    private var activeStateDrawable: Drawable? = null
    private var activeStateColorize: Int? = null


    // --
    // State handling
    // --

    override fun isStateful(): Boolean {
        return true
    }

    override fun onStateChange(state: IntArray?): Boolean {
        return updateDrawable()
    }

    private fun updateDrawable(): Boolean {
        val previousDrawable = activeStateDrawable
        val previousColorize = activeStateColorize
        val checkState = state ?: IntArray(0)
        if (!checkState.contains(android.R.attr.state_enabled)) {
            activeStateColorize = disabledColorize ?: colorize
            if (activeStateColorize != null) {
                if (disabledDrawable != null) {
                    if (colorizeDisabledDrawable == null) {
                        colorizeDisabledDrawable = disabledDrawable?.mutate()
                    }
                } else if (drawable != null && colorizeDrawable == null) {
                    colorizeDrawable = drawable?.mutate()
                }
                activeStateDrawable = colorizeDisabledDrawable ?: colorizeDrawable
            } else {
                activeStateDrawable = disabledDrawable ?: drawable
            }
        } else if (checkState.contains(android.R.attr.state_pressed)) {
            activeStateColorize = pressedColorize ?: colorize
            if (activeStateColorize != null) {
                if (pressedDrawable != null) {
                    if (colorizePressedDrawable == null) {
                        colorizePressedDrawable = pressedDrawable?.mutate()
                    }
                } else if (drawable != null && colorizeDrawable == null) {
                    colorizeDrawable = drawable?.mutate()
                }
                activeStateDrawable = colorizePressedDrawable ?: colorizeDrawable
            } else {
                activeStateDrawable = pressedDrawable ?: drawable
            }
        } else {
            activeStateColorize = colorize
            if (activeStateColorize != null) {
                if (drawable != null && colorizeDrawable == null) {
                    colorizeDrawable = drawable?.mutate()
                }
                activeStateDrawable = colorizeDrawable
            } else {
                activeStateDrawable = drawable
            }
        }
        if (activeStateDrawable !== previousDrawable || activeStateColorize != previousColorize) {
            activeStateDrawable?.colorFilter = null
            activeStateColorize?.let {
                activeStateDrawable?.colorFilter = PorterDuffColorFilter(it, PorterDuff.Mode.SRC_IN)
            }
            activeStateDrawable?.bounds = bounds
            invalidateSelf()
            return true
        }
        return false
    }


    // --
    // Property implementation
    // --

    override fun setAlpha(alpha: Int) {
        // Ignored
    }

    override fun getOpacity(): Int {
        return activeStateDrawable?.opacity ?: PixelFormat.TRANSPARENT
    }

    override fun setColorFilter(colorFilter: ColorFilter?) {
        // Ignored
    }

    override fun getIntrinsicWidth(): Int {
        return activeStateDrawable?.intrinsicWidth ?: super.getIntrinsicWidth()
    }

    override fun getIntrinsicHeight(): Int {
        return activeStateDrawable?.intrinsicHeight ?: super.getIntrinsicHeight()
    }


    // --
    // Draw implementation
    // --

    override fun onBoundsChange(bounds: Rect?) {
        super.onBoundsChange(bounds)
        activeStateDrawable?.bounds = bounds ?: Rect()
    }

    override fun draw(canvas: Canvas) {
        activeStateDrawable?.draw(canvas)
    }

}
