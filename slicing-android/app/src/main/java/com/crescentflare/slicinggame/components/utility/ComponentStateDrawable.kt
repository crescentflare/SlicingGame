package com.crescentflare.slicinggame.components.utility

import android.graphics.Canvas
import android.graphics.ColorFilter
import android.graphics.PixelFormat
import android.graphics.Rect
import android.graphics.drawable.Drawable


/**
 * Component utility: a flexible drawable container for component states
 */
class ComponentStateDrawable : Drawable() {

    // --
    // Members
    // --

    var drawable: Drawable? = null
        set(drawable) {
            if (field !== drawable) {
                field = drawable
                onStateChange(state)
            }
        }

    var pressedDrawable: Drawable? = null
        set(drawable) {
            if (field !== drawable) {
                field = drawable
                onStateChange(state)
            }
        }

    var disabledDrawable: Drawable? = null
        set(drawable) {
            if (field !== drawable) {
                field = drawable
                onStateChange(state)
            }
        }

    private var activeStateDrawable: Drawable? = null


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
        val checkState = state ?: IntArray(0)
        if (!checkState.contains(android.R.attr.state_enabled)) {
            activeStateDrawable = disabledDrawable ?: drawable
        } else if (checkState.contains(android.R.attr.state_pressed)) {
            activeStateDrawable = pressedDrawable ?: drawable
        } else {
            activeStateDrawable = drawable
        }
        if (activeStateDrawable !== previousDrawable) {
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
