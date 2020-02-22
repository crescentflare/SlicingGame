package com.crescentflare.slicinggame.components.containers

import android.annotation.TargetApi
import android.content.Context
import android.graphics.Canvas
import android.graphics.Paint
import android.os.Build
import android.util.AttributeSet
import com.crescentflare.jsoninflator.JsonInflatable
import com.crescentflare.jsoninflator.binder.InflatorBinder
import com.crescentflare.jsoninflator.utility.InflatorMapUtil
import com.crescentflare.slicinggame.components.utility.ViewletUtil
import com.crescentflare.slicinggame.sprites.core.Sprite
import com.crescentflare.slicinggame.sprites.core.SpriteCanvas


/**
 * Container view: provides a container for managing sprites
 */
open class SpriteContainerView : FrameContainerView {

    // --
    // Static: viewlet integration
    // --

    companion object {

        val viewlet: JsonInflatable = object : JsonInflatable {
            override fun create(context: Context): Any {
                return SpriteContainerView(context)
            }

            override fun update(mapUtil: InflatorMapUtil, obj: Any, attributes: Map<String, Any>, parent: Any?, binder: InflatorBinder?): Boolean {
                if (obj is SpriteContainerView) {
                    // Apply grid size
                    obj.gridWidth = mapUtil.optionalFloat(attributes, "gridWidth", 1f)
                    obj.gridHeight = mapUtil.optionalFloat(attributes, "gridHeight", 1f)

                    // Generic view properties
                    ViewletUtil.applyGenericViewAttributes(mapUtil, obj, attributes)
                    return true
                }
                return false
            }

            override fun canRecycle(mapUtil: InflatorMapUtil, obj: Any, attributes: Map<String, Any>): Boolean {
                return obj::class == SpriteContainerView::class
            }
        }
    }


    // --
    // Members
    // --

    private var sprite = Sprite()
    private val paint = Paint(Paint.ANTI_ALIAS_FLAG)
    private val spriteCanvas = SpriteCanvas(paint)


    // --
    // Initialization
    // --

    @JvmOverloads
    constructor(
        context: Context,
        attrs: AttributeSet? = null,
        defStyleAttr: Int = 0)
            : super(context, attrs, defStyleAttr)

    @TargetApi(Build.VERSION_CODES.LOLLIPOP)
    constructor(
        context: Context,
        attrs: AttributeSet?,
        defStyleAttr: Int,
        defStyleRes: Int)
            : super(context, attrs, defStyleAttr, defStyleRes)

    init {
        // No implementation
    }


    // --
    // Configurable values
    // --

    var gridWidth: Float = 1f
        set(gridWidth) {
            val changed = field != gridWidth
            field = gridWidth
            if (changed) {
                requestLayout()
            }
        }

    var gridHeight: Float = 1f
        set(gridHeight) {
            val changed = field != gridHeight
            field = gridHeight
            if (changed) {
                requestLayout()
            }
        }


    // --
    // Drawing
    // --

    override fun onDraw(canvas: Canvas?) {
        canvas?.let {
            it.clipRect(0, 0, width, height)
            spriteCanvas.prepare(it, width.toFloat(), height.toFloat(), gridWidth, gridHeight)
            sprite.draw(spriteCanvas)
        }
    }


    // --
    // Custom layout
    // --

    override fun onMeasure(widthMeasureSpec: Int, heightMeasureSpec: Int) {
        val widthMode = MeasureSpec.getMode(widthMeasureSpec)
        val heightMode = MeasureSpec.getMode(heightMeasureSpec)
        val width = MeasureSpec.getSize(widthMeasureSpec)
        val height = MeasureSpec.getSize(heightMeasureSpec)
        if (widthMode == MeasureSpec.AT_MOST && heightMode == MeasureSpec.AT_MOST) {
            if (width * gridHeight / gridWidth <= height) {
                setMeasuredDimension(width, (width * gridHeight / gridWidth).toInt())
            } else {
                setMeasuredDimension((height * gridWidth / gridHeight).toInt(), height)
            }
        } else if (widthMode == MeasureSpec.EXACTLY && heightMode == MeasureSpec.EXACTLY) {
            setMeasuredDimension(width, height)
        } else if (widthMode == MeasureSpec.AT_MOST || widthMode == MeasureSpec.EXACTLY) {
            setMeasuredDimension(width, (width * gridHeight / gridWidth).toInt())
        } else if (heightMode == MeasureSpec.AT_MOST || heightMode == MeasureSpec.EXACTLY) {
            setMeasuredDimension((height * gridWidth / gridHeight).toInt(), height)
        } else {
            super.onMeasure(widthMeasureSpec, heightMeasureSpec)
        }
    }

}
