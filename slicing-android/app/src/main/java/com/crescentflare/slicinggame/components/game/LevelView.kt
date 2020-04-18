package com.crescentflare.slicinggame.components.game

import android.annotation.TargetApi
import android.content.Context
import android.content.res.Resources
import android.graphics.Color
import android.graphics.PointF
import android.os.Build
import android.util.AttributeSet
import android.view.Gravity
import com.crescentflare.jsoninflator.JsonInflatable
import com.crescentflare.jsoninflator.binder.InflatorBinder
import com.crescentflare.jsoninflator.utility.InflatorMapUtil
import com.crescentflare.slicinggame.R
import com.crescentflare.slicinggame.components.basicviews.ImageView
import com.crescentflare.slicinggame.components.basicviews.TextView
import com.crescentflare.slicinggame.components.containers.FrameContainerView
import com.crescentflare.slicinggame.components.containers.SpriteContainerView
import com.crescentflare.slicinggame.components.utility.ImageSource
import com.crescentflare.slicinggame.components.utility.ViewletUtil
import com.crescentflare.slicinggame.infrastructure.geometry.Polygon
import com.crescentflare.slicinggame.infrastructure.geometry.Vector
import com.crescentflare.slicinggame.infrastructure.physics.Physics
import com.crescentflare.slicinggame.sprites.core.Sprite
import com.crescentflare.unilayout.helpers.UniLayoutParams
import java.lang.ref.WeakReference
import kotlin.math.max


/**
 * Game view: contains all components for the playable level area
 */
open class LevelView : FrameContainerView, Physics.Listener {

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
                    obj.sliceWidth = mapUtil.optionalFloat(attributes, "sliceWidth", 0f)

                    // Apply background
                    obj.backgroundImage = ImageSource.fromValue(attributes["backgroundImage"])

                    // Apply clear goal
                    obj.requireClearRate = mapUtil.optionalInteger(attributes, "requireClearRate", 100)

                    // Apply update frames per second
                    obj.fps = mapUtil.optionalInteger(attributes, "fps", 60)

                    // Apply debug settings
                    obj.drawPhysicsBoundaries = mapUtil.optionalBoolean(attributes, "drawPhysicsBoundaries", false)

                    // Apply sprites
                    val spriteList = mapUtil.optionalObjectList(attributes, "sprites")
                    obj.clearSprites()
                    for (spriteItem in spriteList) {
                        mapUtil.asStringObjectMap(spriteItem)?.let {
                            val sprite = Sprite()
                            sprite.x = mapUtil.optionalFloat(it, "x", 0f)
                            sprite.y = mapUtil.optionalFloat(it, "y", 0f)
                            sprite.width = mapUtil.optionalFloat(it, "width", 1f)
                            sprite.height = mapUtil.optionalFloat(it, "height", 1f)
                            obj.addSprite(sprite)
                        }
                    }

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
    // Physics listener
    // --

    interface Listener {

        fun onLethalHit()

    }


    // --
    // Members
    // --

    var listener: Listener?
        get() = listenerReference?.get()
        set(listener) {
            listenerReference = if (listener != null) {
                WeakReference(listener)
            } else {
                null
            }
        }

    private var backgroundView = ImageView(context)
    private var canvasViews = mutableListOf(LevelCanvasView(context))
    private var spriteContainerView = SpriteContainerView(context)
    private var progressView = TextView(context)
    private val progressViewMargin = resources.getDimensionPixelSize(R.dimen.text) + (Resources.getSystem().displayMetrics.density * 8).toInt()
    private var listenerReference: WeakReference<Listener>? = null


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
        val backgroundLayoutParams = UniLayoutParams(UniLayoutParams.MATCH_PARENT, UniLayoutParams.MATCH_PARENT)
        backgroundLayoutParams.bottomMargin = progressViewMargin
        backgroundView.layoutParams = backgroundLayoutParams
        backgroundView.scaleType = android.widget.ImageView.ScaleType.CENTER_CROP
        addView(backgroundView)

        // Add level canvas
        val canvasLayoutParams = UniLayoutParams(UniLayoutParams.MATCH_PARENT, UniLayoutParams.MATCH_PARENT)
        canvasLayoutParams.bottomMargin = progressViewMargin
        canvasViews[0].layoutParams = canvasLayoutParams
        canvasViews[0].setBackgroundColor(Color.WHITE)
        addView(canvasViews[0])

        // Add sprite container
        val spriteContainerLayoutParams = UniLayoutParams(UniLayoutParams.MATCH_PARENT, UniLayoutParams.MATCH_PARENT)
        spriteContainerLayoutParams.bottomMargin = progressViewMargin
        spriteContainerView.layoutParams = spriteContainerLayoutParams
        spriteContainerView.physicsListener = this
        addView(spriteContainerView)

        // Add progress view
        val progressLayoutParams = UniLayoutParams(UniLayoutParams.MATCH_PARENT, UniLayoutParams.WRAP_CONTENT)
        progressLayoutParams.verticalGravity = 1f
        progressView.layoutParams = progressLayoutParams
        progressView.maxLines = 1
        progressView.gravity = Gravity.CENTER_HORIZONTAL
        progressView.text = "0 / 100%"
        addView(progressView)
    }


    // --
    // Sprites
    // --

    fun addSprite(sprite: Sprite) {
        spriteContainerView.addSprite(sprite)
    }

    fun clearSprites() {
        spriteContainerView.clearSprites()
    }


    // --
    // Slicing
    // --

    fun slice(vector: Vector) {
        // Prepare slice vectors
        val topLeft = PointF(0f, 0f)
        val bottomRight = PointF(levelWidth, levelHeight)
        val offsetVector = vector.perpendicular().unit() * (sliceWidth / 2)
        val sliceVector = vector.translated(-offsetVector.x, -offsetVector.y).stretchedToEdges(topLeft, bottomRight)
        val reversedVector = vector.reversed().translated(offsetVector.x, offsetVector.y).stretchedToEdges(topLeft, bottomRight)

        // Check for collision
        val slicePolygon = Polygon(listOf(sliceVector.end, sliceVector.start, reversedVector.end, reversedVector.start))
        if (spriteContainerView.spritesOnPolygon(slicePolygon)) {
            onLethalCollision()
            return
        }

        // Apply slice
        val originalCanvasViews = mutableListOf<LevelCanvasView>().apply { addAll(canvasViews) }
        val insertDuplicateIndex = max(indexOfChild(canvasViews[0]), 0)
        for (canvasView in originalCanvasViews) {
            val normalClearRate = canvasView.clearRateForSlice(sliceVector)
            val reversedClearRate = canvasView.clearRateForSlice(reversedVector)
            val normalSpriteCount = spriteContainerView.spritesPerSlice(sliceVector, canvasView.slicedBoundary)
            val reversedSpriteCount = spriteContainerView.spritesPerSlice(reversedVector, canvasView.slicedBoundary)
            if (normalSpriteCount > 0 && reversedSpriteCount > 0) {
                (canvasView.clone() as? LevelCanvasView)?.let { duplicateCanvasView ->
                    canvasViews.add(duplicateCanvasView)
                    addView(duplicateCanvasView, insertDuplicateIndex)
                    duplicateCanvasView.slice(reversedVector)
                }
                canvasView.slice(sliceVector)
            } else if (reversedSpriteCount > normalSpriteCount || (reversedSpriteCount == normalSpriteCount && reversedClearRate < normalClearRate)) {
                canvasView.slice(reversedVector)
            } else {
                canvasView.slice(sliceVector)
            }
        }

        // Update state
        val remainingProgress = canvasViews.map { it.remainingSliceArea() }.reduce { acc, area -> acc + area }
        spriteContainerView.visibility = if (cleared()) INVISIBLE else VISIBLE
        spriteContainerView.clearCollisionBoundaries()
        for (canvasView in canvasViews) {
            canvasView.visibility = if (cleared()) INVISIBLE else VISIBLE
            spriteContainerView.addCollisionBoundaries(canvasView.slicedBoundary)
        }
        progressView.text = "${100 - remainingProgress.toInt()} / $requireClearRate%"
    }

    fun resetSlices() {
        // Remove duplicated canvas views and reset slices on the original one
        for (canvasView in canvasViews) {
            if (canvasView !== canvasViews.firstOrNull()) {
                removeView(canvasView)
            }
        }
        canvasViews = mutableListOf(canvasViews[0])
        canvasViews[0].resetSlices()

        // Update state
        val remainingProgress = canvasViews.map { it.remainingSliceArea() }.reduce { acc, area -> acc + area }
        spriteContainerView.visibility = if (cleared()) INVISIBLE else VISIBLE
        spriteContainerView.clearCollisionBoundaries()
        for (canvasView in canvasViews) {
            canvasView.visibility = if (cleared()) INVISIBLE else VISIBLE
            spriteContainerView.addCollisionBoundaries(canvasView.slicedBoundary)
        }
        progressView.text = "${100 - remainingProgress.toInt()} / $requireClearRate%"
    }

    fun transformedSliceVector(vector: Vector): Vector {
        val translatedVector = vector.translated(-left.toFloat(), -top.toFloat())
        return translatedVector.scaled(levelWidth / canvasViews[0].width.toFloat(), levelHeight / canvasViews[0].height.toFloat())
    }

    fun setSliceVector(vector: Vector?, screenSpace: Boolean = false): Boolean {
        val sliceVector = if (vector != null) {
            if (screenSpace) transformedSliceVector(vector) else vector
        } else {
            null
        }
        if (sliceVector?.isValid() == true) {
            return spriteContainerView.setSliceVector(sliceVector)
        }
        return spriteContainerView.setSliceVector(null)
    }


    // --
    // Obtain state
    // --

    fun cleared(): Boolean {
        val remainingProgress = canvasViews.map { it.remainingSliceArea() }.reduce { acc, area -> acc + area }
        return 100 - remainingProgress.toInt() >= requireClearRate
    }


    // --
    // Configurable values
    // --

    var levelWidth: Float = 1f
        set(levelWidth) {
            field = levelWidth
            for (canvasView in canvasViews) {
                canvasView.canvasWidth = levelWidth
            }
            spriteContainerView.gridWidth = levelWidth
        }

    var levelHeight: Float = 1f
        set(levelHeight) {
            field = levelHeight
            for (canvasView in canvasViews) {
                canvasView.canvasHeight = levelHeight
            }
            spriteContainerView.gridHeight = levelHeight
        }

    var sliceWidth: Float = 0f
        set(sliceWidth) {
            field = sliceWidth
            spriteContainerView.sliceWidth = sliceWidth
            spriteContainerView.clearCollisionBoundaries()
            for (canvasView in canvasViews) {
                spriteContainerView.addCollisionBoundaries(canvasView.slicedBoundary)
            }
        }

    var backgroundImage: ImageSource?
        get() = backgroundView.source
        set(backgroundImage) {
            backgroundView.source = backgroundImage
        }

    var requireClearRate: Int = 100
        set(requireClearRate) {
            field = requireClearRate
            val remainingProgress = canvasViews.map { it.remainingSliceArea() }.reduce { acc, area -> acc + area }
            for (canvasView in canvasViews) {
                canvasView.visibility = if (cleared()) INVISIBLE else VISIBLE
            }
            progressView.text = "${100 - remainingProgress.toInt()} / $requireClearRate%"
            spriteContainerView.visibility = if (cleared()) INVISIBLE else VISIBLE
        }

    var fps: Int
        get() = spriteContainerView.fps
        set(fps) {
            spriteContainerView.fps = fps
        }

    var drawPhysicsBoundaries: Boolean
        get() = spriteContainerView.drawPhysicsBoundaries
        set(drawPhysicsBoundaries) {
            spriteContainerView.drawPhysicsBoundaries = drawPhysicsBoundaries
        }


    // --
    // Physics delegate
    // --

    override fun onLethalCollision() {
        listener?.onLethalHit()
    }


    // --
    // Custom layout
    // --

    override fun onMeasure(widthMeasureSpec: Int, heightMeasureSpec: Int) {
        super.onMeasure(widthMeasureSpec, heightMeasureSpec)
        setMeasuredDimension(canvasViews[0].measuredWidth, canvasViews[0].measuredHeight + progressViewMargin)
    }

}
