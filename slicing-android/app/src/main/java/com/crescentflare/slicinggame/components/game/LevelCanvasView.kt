package com.crescentflare.slicinggame.components.game

import android.annotation.TargetApi
import android.content.Context
import android.graphics.Canvas
import android.graphics.Path
import android.graphics.PointF
import android.os.Build
import android.util.AttributeSet
import android.view.View
import com.crescentflare.jsoninflator.JsonInflatable
import com.crescentflare.jsoninflator.binder.InflatorBinder
import com.crescentflare.jsoninflator.utility.InflatorMapUtil
import com.crescentflare.slicinggame.components.utility.ViewletUtil
import com.crescentflare.slicinggame.infrastructure.geometry.Polygon
import com.crescentflare.slicinggame.infrastructure.geometry.Vector
import com.crescentflare.unilayout.containers.UniFrameContainer
import com.crescentflare.unilayout.helpers.UniLayoutParams


/**
 * Game view: a level canvas layer
 */
open class LevelCanvasView : UniFrameContainer {

    // --
    // Static: viewlet integration
    // --

    companion object {

        val viewlet: JsonInflatable = object : JsonInflatable {
            override fun create(context: Context): Any {
                return LevelCanvasView(context)
            }

            override fun update(mapUtil: InflatorMapUtil, obj: Any, attributes: Map<String, Any>, parent: Any?, binder: InflatorBinder?): Boolean {
                if (obj is LevelCanvasView) {
                    // Apply canvas size
                    obj.canvasWidth = mapUtil.optionalFloat(attributes, "canvasWidth", 1f)
                    obj.canvasHeight = mapUtil.optionalFloat(attributes, "canvasHeight", 1f)

                    // Apply slices
                    val sliceList = mapUtil.optionalFloatList(attributes, "slices")
                    obj.resetSlices()
                    for (index in sliceList.indices) {
                        if (index % 4 == 0 && index + 3 < sliceList.size) {
                            obj.slice(Vector(PointF(sliceList[index], sliceList[index + 1]), PointF(sliceList[index + 2], sliceList[index + 3])))
                        }
                    }

                    // Generic view properties
                    ViewletUtil.applyGenericViewAttributes(mapUtil, obj, attributes)
                    return true
                }
                return false
            }

            override fun canRecycle(mapUtil: InflatorMapUtil, obj: Any, attributes: Map<String, Any>): Boolean {
                return obj::class == LevelCanvasView::class
            }
        }
    }


    // --
    // Members
    // --

    private var drawView = View(context)
    private var clipPolygon = Polygon(mutableListOf(PointF(0f, 0f), PointF(1f, 0f), PointF(1f, 1f), PointF(0f, 1f)))
    private var clipPath: Path? = null


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
        drawView.layoutParams = UniLayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT)
        addView(drawView)
    }


    // --
    // Configurable values
    // --

    fun slice(vector: Vector) {
        clipPolygon.sliced(vector)?.let {
            clipPolygon = it
            updateClipPath()
        }
    }

    fun resetSlices() {
        clipPolygon = Polygon(mutableListOf(PointF(0f, 0f), PointF(canvasWidth, 0f), PointF(canvasWidth, canvasHeight), PointF(0f, canvasHeight)))
        updateClipPath()
    }


    // --
    // Configurable values
    // --

    override fun setBackgroundColor(color: Int) {
        drawView.setBackgroundColor(color)
    }

    var canvasWidth: Float = 1f
        set(canvasWidth) {
            val changed = field != canvasWidth
            field = canvasWidth
            if (changed) {
                clipPolygon = Polygon(mutableListOf(PointF(0f, 0f), PointF(canvasWidth, 0f), PointF(canvasWidth, canvasHeight), PointF(0f, canvasHeight)))
                updateClipPath()
            }
        }

    var canvasHeight: Float = 1f
        set(canvasHeight) {
            val changed = field != canvasHeight
            field = canvasHeight
            if (changed) {
                clipPolygon = Polygon(mutableListOf(PointF(0f, 0f), PointF(canvasWidth, 0f), PointF(canvasWidth, canvasHeight), PointF(0f, canvasHeight)))
                updateClipPath()
            }
        }


    // --
    // Update clipping
    // --

    private fun updateClipPath() {
        clipPath = clipPolygon.asPath(width.toFloat() / canvasWidth, height.toFloat() / canvasHeight)
        invalidate()
    }

    override fun onSizeChanged(w: Int, h: Int, oldw: Int, oldh: Int) {
        super.onSizeChanged(w, h, oldw, oldh)
        updateClipPath()
    }

    override fun dispatchDraw(canvas: Canvas?) {
        val clipPath = this.clipPath
        if (clipPath != null) {
            val save = canvas?.save()
            canvas?.clipPath(clipPath)
            super.dispatchDraw(canvas)
            if (save != null) {
                canvas.restoreToCount(save)
            }
        } else {
            super.dispatchDraw(canvas)
        }
    }

}