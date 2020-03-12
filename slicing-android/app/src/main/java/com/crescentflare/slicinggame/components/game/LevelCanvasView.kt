package com.crescentflare.slicinggame.components.game

import android.annotation.TargetApi
import android.content.Context
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Path
import android.graphics.PointF
import android.graphics.drawable.ColorDrawable
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
open class LevelCanvasView : UniFrameContainer, Cloneable {

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

    public override fun clone(): Any {
        // Create view and copy layout properties
        val view = LevelCanvasView(context)
        val layoutParams = UniLayoutParams(UniLayoutParams.MATCH_PARENT, UniLayoutParams.MATCH_PARENT)
        layoutParams.width = layoutParams.width
        layoutParams.height = layoutParams.height
        layoutParams.bottomMargin = (layoutParams as? MarginLayoutParams)?.bottomMargin ?: 0
        view.setBackgroundColor((drawView.background as? ColorDrawable)?.color ?: Color.TRANSPARENT)

        // Copy other properties and return result
        view.canvasWidth = canvasWidth
        view.canvasHeight = canvasHeight
        view.clipPolygon = Polygon(clipPolygon.points)
        return view
    }


    // --
    // Slicing
    // --

    val slicedBoundary: Polygon
        get() = clipPolygon

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

    fun clearRateForSlice(vector: Vector): Float {
        clipPolygon.sliced(vector)?.let {
            val canvasSurface = canvasWidth * canvasHeight
            if (canvasSurface > 0) {
                val newClearRate = 100 - it.calculateSurfaceArea() * 100 / canvasSurface
                return newClearRate - clearRate()
            }
        }
        return 0f
    }


    // --
    // Obtain state
    // --

    fun clearRate(): Float {
        return 100f - remainingSliceArea()
    }

    fun remainingSliceArea(): Float {
        val canvasSurface = canvasWidth * canvasHeight
        if (canvasSurface > 0) {
            return clipPolygon.calculateSurfaceArea() * 100 / canvasSurface
        }
        return 100f
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

    override fun onSizeChanged(width: Int, height: Int, oldWidth: Int, oldHeight: Int) {
        super.onSizeChanged(width, height, oldWidth, oldHeight)
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


    // --
    // Custom layout
    // --

    override fun onMeasure(widthMeasureSpec: Int, heightMeasureSpec: Int) {
        val widthMode = MeasureSpec.getMode(widthMeasureSpec)
        val heightMode = MeasureSpec.getMode(heightMeasureSpec)
        val width = MeasureSpec.getSize(widthMeasureSpec)
        val height = MeasureSpec.getSize(heightMeasureSpec)
        if (widthMode == MeasureSpec.AT_MOST && heightMode == MeasureSpec.AT_MOST) {
            if (width * canvasHeight / canvasWidth <= height) {
                setMeasuredDimension(width, (width * canvasHeight / canvasWidth).toInt())
            } else {
                setMeasuredDimension((height * canvasWidth / canvasHeight).toInt(), height)
            }
        } else if (widthMode == MeasureSpec.EXACTLY && heightMode == MeasureSpec.EXACTLY) {
            setMeasuredDimension(width, height)
        } else if (widthMode == MeasureSpec.AT_MOST || widthMode == MeasureSpec.EXACTLY) {
            setMeasuredDimension(width, (width * canvasHeight / canvasWidth).toInt())
        } else if (heightMode == MeasureSpec.AT_MOST || heightMode == MeasureSpec.EXACTLY) {
            setMeasuredDimension((height * canvasWidth / canvasHeight).toInt(), height)
        } else {
            super.onMeasure(widthMeasureSpec, heightMeasureSpec)
        }
    }

}
