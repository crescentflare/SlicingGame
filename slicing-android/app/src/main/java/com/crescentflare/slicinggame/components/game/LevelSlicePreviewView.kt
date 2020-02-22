package com.crescentflare.slicinggame.components.game

import android.annotation.TargetApi
import android.content.Context
import android.graphics.*
import android.os.Build
import android.util.AttributeSet
import com.crescentflare.jsoninflator.JsonInflatable
import com.crescentflare.jsoninflator.binder.InflatorBinder
import com.crescentflare.jsoninflator.utility.InflatorMapUtil
import com.crescentflare.slicinggame.R
import com.crescentflare.slicinggame.components.utility.ViewletUtil
import com.crescentflare.slicinggame.infrastructure.geometry.Vector
import com.crescentflare.unilayout.containers.UniFrameContainer


/**
 * Game view: shows a helper line for previewing a slice
 */
open class LevelSlicePreviewView : UniFrameContainer {

    // --
    // Static: viewlet integration
    // --

    companion object {

        val viewlet: JsonInflatable = object : JsonInflatable {
            override fun create(context: Context): Any {
                return LevelSlicePreviewView(context)
            }

            override fun update(mapUtil: InflatorMapUtil, obj: Any, attributes: Map<String, Any>, parent: Any?, binder: InflatorBinder?): Boolean {
                if (obj is LevelSlicePreviewView) {
                    // Apply start position
                    val startPositionList = mapUtil.optionalDimensionList(attributes, "start")
                    if (startPositionList.size == 2) {
                        obj.start = Point(startPositionList[0], startPositionList[1])
                    } else {
                        obj.start = null
                    }

                    // Apply end position
                    val endPositionList = mapUtil.optionalDimensionList(attributes, "end")
                    if (endPositionList.size == 2) {
                        obj.end = Point(endPositionList[0], endPositionList[1])
                    } else {
                        obj.end = null
                    }

                    // Apply colors
                    obj.color = mapUtil.optionalColor(attributes, "color", Color.TRANSPARENT)
                    obj.stretchedColor = mapUtil.optionalColor(attributes, "stretchedColor", Color.TRANSPARENT)

                    // Generic view properties
                    ViewletUtil.applyGenericViewAttributes(mapUtil, obj, attributes)
                    return true
                }
                return false
            }

            override fun canRecycle(mapUtil: InflatorMapUtil, obj: Any, attributes: Map<String, Any>): Boolean {
                return obj::class == LevelSlicePreviewView::class
            }
        }
    }


    // --
    // Members
    // --

    private val paint = Paint(Paint.ANTI_ALIAS_FLAG)
    private val dotSize = resources.getDimensionPixelSize(R.dimen.slicePreviewDot).toFloat()
    private val lineWidth = resources.getDimensionPixelSize(R.dimen.slicePreviewWidth).toFloat()
    private val stretchedLineWidth = resources.getDimensionPixelSize(R.dimen.slicePreviewStretchedWidth).toFloat()
    private val lineDash = resources.getDimensionPixelSize(R.dimen.slicePreviewDash).toFloat()
    private val dashEffect = DashPathEffect(floatArrayOf(lineDash, lineDash), 0f)
    private var linePath: Path? = null
    private var stretchedLinePath: Path? = null
    private var startDotOval: RectF? = null
    private var endDotOval: RectF? = null


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

    var start: Point? = null
        set(start) {
            val changed = field != start
            field = start
            if (changed) {
                updateShapes()
                invalidate()
            }
        }

    var end: Point? = null
        set(end) {
            val changed = field != end
            field = end
            if (changed) {
                updateShapes()
                invalidate()
            }
        }

    var color: Int = Color.TRANSPARENT
        set(color) {
            val changed = field != color
            field = color
            if (changed) {
                invalidate()
            }
        }

    var stretchedColor: Int = Color.TRANSPARENT
        set(stretchedColor) {
            val changed = field != stretchedColor
            field = stretchedColor
            if (changed) {
                invalidate()
            }
        }


    // --
    // Update shapes
    // --

    private fun updateShapes() {
        // Create slice vectors
        val checkStart = start
        val checkEnd = end
        val sliceVector = if (checkStart != null && checkEnd != null) {
            Vector(PointF(checkStart.x.toFloat(), checkStart.y.toFloat()), PointF(checkEnd.x.toFloat(), checkEnd.y.toFloat()))
        } else {
            null
        }
        val stretchedSliceVector = sliceVector?.stretchedToEdges(PointF(0f, 0f), PointF(width.toFloat(), height.toFloat()))

        // Set up line
        linePath = if (sliceVector != null && sliceVector.isValid()) {
            Path().apply {
                moveTo(sliceVector.start.x, sliceVector.start.y)
                lineTo(sliceVector.end.x, sliceVector.end.y)
            }
        } else {
            null
        }

        // Set up stretched line
        stretchedLinePath = if (stretchedSliceVector != null && stretchedSliceVector.isValid()) {
            Path().apply {
                moveTo(stretchedSliceVector.start.x, stretchedSliceVector.start.y)
                lineTo(stretchedSliceVector.end.x, stretchedSliceVector.end.y)
            }
        } else {
            null
        }

        // Set up start/end dots
        val dotRadius = dotSize / 2
        startDotOval = null
        endDotOval = null
        start?.let {
            startDotOval = RectF(it.x - dotRadius, it.y - dotRadius, it.x + dotRadius, it.y + dotRadius)
        }
        end?.let {
            endDotOval = RectF(it.x - dotRadius, it.y - dotRadius, it.x + dotRadius, it.y + dotRadius)
        }

        // Update draw state
        setWillNotDraw(linePath == null && stretchedLinePath == null && startDotOval == null && endDotOval == null)
    }


    // --
    // Custom drawing
    // --

    override fun onDraw(canvas: Canvas?) {
        // Draw stretched line
        super.onDraw(canvas)
        stretchedLinePath?.let {
            paint.color = stretchedColor
            paint.strokeWidth = stretchedLineWidth
            paint.style = Paint.Style.STROKE
            paint.pathEffect = null
            canvas?.drawPath(it, paint)
        }

        // Draw start/end dots
        startDotOval?.let {
            paint.color = color
            paint.style = Paint.Style.FILL
            canvas?.drawOval(it, paint)
        }
        endDotOval?.let {
            paint.color = color
            paint.style = Paint.Style.FILL
            canvas?.drawOval(it, paint)
        }

        // Draw line
        linePath?.let {
            paint.color = color
            paint.strokeWidth = lineWidth
            paint.style = Paint.Style.STROKE
            paint.pathEffect = dashEffect
            canvas?.drawPath(it, paint)
        }
    }

    override fun onSizeChanged(width: Int, height: Int, oldWidth: Int, oldHeight: Int) {
        super.onSizeChanged(width, height, oldWidth, oldHeight)
        updateShapes()
    }

}
