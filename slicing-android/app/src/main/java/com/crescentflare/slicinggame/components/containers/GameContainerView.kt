package com.crescentflare.slicinggame.components.containers

import android.annotation.SuppressLint
import android.annotation.TargetApi
import android.content.Context
import android.content.res.Resources
import android.graphics.Color
import android.graphics.Point
import android.graphics.PointF
import android.os.Build
import android.util.AttributeSet
import android.view.MotionEvent
import androidx.core.content.ContextCompat
import androidx.core.view.setMargins
import com.crescentflare.jsoninflator.JsonInflatable
import com.crescentflare.jsoninflator.binder.InflatorBinder
import com.crescentflare.jsoninflator.utility.InflatorMapUtil
import com.crescentflare.slicinggame.R
import com.crescentflare.slicinggame.components.game.LevelCanvasView
import com.crescentflare.slicinggame.components.game.LevelSlicePreviewView
import com.crescentflare.slicinggame.components.utility.ViewletUtil
import com.crescentflare.slicinggame.infrastructure.geometry.Vector
import com.crescentflare.unilayout.helpers.UniLayoutParams


/**
 * Container view: layout of game components and slice interaction
 */
open class GameContainerView : FrameContainerView {

    // --
    // Static: viewlet integration
    // --

    companion object {

        val viewlet: JsonInflatable = object : JsonInflatable {
            override fun create(context: Context): Any {
                return GameContainerView(context)
            }

            override fun update(mapUtil: InflatorMapUtil, obj: Any, attributes: Map<String, Any>, parent: Any?, binder: InflatorBinder?): Boolean {
                if (obj is GameContainerView) {
                    // Apply level size
                    obj.levelWidth = mapUtil.optionalFloat(attributes, "levelWidth", 1f)
                    obj.levelHeight = mapUtil.optionalFloat(attributes, "levelHeight", 1f)

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
                return obj::class == GameContainerView::class
            }
        }
    }


    // --
    // Members
    // --

    private var canvasView = LevelCanvasView(context)
    private var slicePreviewView = LevelSlicePreviewView(context)
    private var dragStart: PointF? = null
    private var dragEnd: PointF? = null
    private var dragPointerId = 0
    private val minimumDragDistance = Resources.getSystem().displayMetrics.density * 32


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
        // Add level canvas
        val canvasLayoutParams = UniLayoutParams(UniLayoutParams.WRAP_CONTENT, UniLayoutParams.WRAP_CONTENT)
        canvasLayoutParams.setMargins(resources.getDimensionPixelSize(R.dimen.pagePadding))
        canvasLayoutParams.horizontalGravity = 0.5f
        canvasLayoutParams.verticalGravity = 0.5f
        canvasView.layoutParams = canvasLayoutParams
        canvasView.setBackgroundColor(Color.WHITE)
        addView(canvasView)

        // Add slice preview
        slicePreviewView.layoutParams = UniLayoutParams(UniLayoutParams.MATCH_PARENT, UniLayoutParams.MATCH_PARENT)
        slicePreviewView.color = ContextCompat.getColor(context, R.color.slicePreviewLine)
        slicePreviewView.stretchedColor = ContextCompat.getColor(context, R.color.stretchedSlicePreviewLine)
        addView(slicePreviewView)
    }


    // --
    // Configurable values
    // --

    fun slice(vector: Vector) {
        canvasView.slice(vector)
    }

    fun resetSlices() {
        canvasView.resetSlices()
    }


    // --
    // Configurable values
    // --

    var levelWidth: Float = 1f
        set(levelWidth) {
            field = levelWidth
            canvasView.canvasWidth = levelWidth
        }

    var levelHeight: Float = 1f
        set(levelHeight) {
            field = levelHeight
            canvasView.canvasHeight = levelHeight
        }


    // --
    // Interaction
    // --

    @SuppressLint("ClickableViewAccessibility")
    override fun onTouchEvent(event: MotionEvent?): Boolean {
        if (event != null) {
            when (event.action) {
                MotionEvent.ACTION_DOWN, MotionEvent.ACTION_POINTER_DOWN -> {
                    if (dragStart == null && event.pointerCount > 0) {
                        dragStart = PointF(event.getX(0), event.getY(0))
                        dragEnd = dragStart
                        dragPointerId = event.getPointerId(0)
                        dragStart?.let {
                            slicePreviewView.start = Point(it.x.toInt(), it.y.toInt())
                        }
                    }
                    return true
                }
                MotionEvent.ACTION_MOVE -> {
                    if (dragStart != null && dragEnd != null) {
                        for (i in 0 until event.pointerCount) {
                            if (event.getPointerId(i) == dragPointerId) {
                                dragEnd = PointF(event.getX(i), event.getY(i))
                                val vectorStart = dragStart
                                val vectorEnd = dragEnd
                                if (vectorStart != null && vectorEnd != null) {
                                    val viewVector = Vector(vectorStart, vectorEnd)
                                    slicePreviewView.end = if (viewVector.distance() >= minimumDragDistance) {
                                        Point(vectorEnd.x.toInt(), vectorEnd.y.toInt())
                                    } else {
                                        null
                                    }
                                }
                                break
                            }
                        }
                        return true
                    }
                }
                MotionEvent.ACTION_UP, MotionEvent.ACTION_POINTER_UP -> {
                    if (dragStart != null && dragEnd != null) {
                        for (i in 0 until event.pointerCount) {
                            if (event.getPointerId(i) == dragPointerId) {
                                // Update final end position
                                dragEnd = PointF(event.getX(i), event.getY(i))

                                // Make vector and slice
                                val vectorStart = dragStart
                                val vectorEnd = dragEnd
                                if (vectorStart != null && vectorEnd != null && canvasView.width > 0 && canvasView.height > 0) {
                                    val viewVector = Vector(vectorStart, vectorEnd)
                                    if (viewVector.distance() >= minimumDragDistance) {
                                        val canvasVector = viewVector.translated(-canvasView.left.toFloat(), -canvasView.top.toFloat())
                                        val sliceVector = canvasVector.scaled(levelWidth / canvasView.width.toFloat(), levelHeight / canvasView.height.toFloat())
                                        if (sliceVector.isValid()) {
                                            slice(sliceVector.stretchedToEdges(PointF(0f, 0f), PointF(levelWidth, levelHeight)))
                                        }
                                    }
                                }

                                // Reset dragging state
                                dragStart = null
                                dragEnd = null
                                slicePreviewView.start = null
                                slicePreviewView.end = null
                                break
                            }
                        }
                        return true
                    }
                }
            }
        }
        return super.onTouchEvent(event)
    }

}
