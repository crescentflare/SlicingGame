package com.crescentflare.slicinggame.components.game

import android.annotation.TargetApi
import android.content.Context
import android.graphics.Color
import android.graphics.PointF
import android.os.Build
import android.util.AttributeSet
import com.crescentflare.jsoninflator.JsonInflatable
import com.crescentflare.jsoninflator.binder.InflatorBinder
import com.crescentflare.jsoninflator.utility.InflatorMapUtil
import com.crescentflare.slicinggame.components.basicviews.ImageView
import com.crescentflare.slicinggame.components.containers.FrameContainerView
import com.crescentflare.slicinggame.components.utility.ImageSource
import com.crescentflare.slicinggame.components.utility.ViewletUtil
import com.crescentflare.slicinggame.infrastructure.geometry.Vector
import com.crescentflare.unilayout.helpers.UniLayoutParams


/**
 * Game view: contains all components for the playable level area
 */
open class LevelView : FrameContainerView {

    // --
    // Static: viewlet integration
    // --

    companion object {

        val viewlet: JsonInflatable = object : JsonInflatable {
            override fun create(context: Context): Any {
                return LevelView(context)
            }

            override fun update(mapUtil: InflatorMapUtil, obj: Any, attributes: Map<String, Any>, parent: Any?, binder: InflatorBinder?): Boolean {
                if (obj is LevelView) {
                    // Apply level size
                    obj.levelWidth = mapUtil.optionalFloat(attributes, "levelWidth", 1f)
                    obj.levelHeight = mapUtil.optionalFloat(attributes, "levelHeight", 1f)

                    // Apply background
                    obj.backgroundImage = ImageSource.fromValue(attributes["backgroundImage"])

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
                return obj::class == LevelView::class
            }
        }
    }


    // --
    // Members
    // --

    private var backgroundView = ImageView(context)
    private var canvasView = LevelCanvasView(context)


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
        // Add background
        backgroundView.layoutParams = UniLayoutParams(UniLayoutParams.MATCH_PARENT, UniLayoutParams.MATCH_PARENT)
        backgroundView.scaleType = android.widget.ImageView.ScaleType.CENTER_CROP
        addView(backgroundView)

        // Add level canvas
        canvasView.layoutParams = UniLayoutParams(UniLayoutParams.MATCH_PARENT, UniLayoutParams.MATCH_PARENT)
        canvasView.setBackgroundColor(Color.WHITE)
        addView(canvasView)
    }


    // --
    // Slicing
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

    var backgroundImage: ImageSource?
        get() = backgroundView.source
        set(backgroundImage) {
            backgroundView.source = backgroundImage
        }


    // --
    // Custom layout
    // --

    override fun onMeasure(widthMeasureSpec: Int, heightMeasureSpec: Int) {
        super.onMeasure(widthMeasureSpec, heightMeasureSpec)
        setMeasuredDimension(canvasView.measuredWidth, canvasView.measuredHeight)
    }

}
