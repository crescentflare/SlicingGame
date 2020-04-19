package com.crescentflare.slicinggame.components.containers

import android.annotation.SuppressLint
import android.annotation.TargetApi
import android.content.Context
import android.content.res.Resources
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
import com.crescentflare.slicinggame.components.game.LevelSlicePreviewView
import com.crescentflare.slicinggame.components.game.LevelView
import com.crescentflare.slicinggame.components.utility.ImageSource
import com.crescentflare.slicinggame.components.utility.ViewletUtil
import com.crescentflare.slicinggame.infrastructure.events.AppEvent
import com.crescentflare.slicinggame.infrastructure.events.AppEventObserver
import com.crescentflare.slicinggame.infrastructure.geometry.Vector
import com.crescentflare.slicinggame.sprites.core.Sprite
import com.crescentflare.unilayout.helpers.UniLayoutParams


/**
 * Container view: layout of game components and slice interaction
 */
open class GameContainerView : FrameContainerView, LevelView.Listener {

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
                    obj.sliceWidth = mapUtil.optionalFloat(attributes, "sliceWidth", 0f)

                    // Apply background
                    obj.backgroundImage = ImageSource.fromValue(attributes["backgroundImage"])

                    // Apply clear goal
                    obj.requireClearRate = mapUtil.optionalInteger(attributes, "requireClearRate", 100)

                    // Apply events
                    obj.clearEvent = AppEvent.fromValue(attributes["clearEvent"])
                    obj.lethalHitEvents = AppEvent.fromValues(attributes["lethalHitEvents"] ?: attributes["lethalHitEvent"])

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

                    // Chain event observer
                    if (parent is AppEventObserver) {
                        obj.eventObserver = parent
                    }
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

    private var levelView = LevelView(context)
    private var slicePreviewView = LevelSlicePreviewView(context)
    private var dragStart: PointF? = null
    private var dragEnd: PointF? = null
    private var currentSlice: LevelView.SliceResult? = null
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
        // Add level
        val levelLayoutParams = UniLayoutParams(UniLayoutParams.WRAP_CONTENT, UniLayoutParams.WRAP_CONTENT)
        levelLayoutParams.setMargins(resources.getDimensionPixelSize(R.dimen.pagePadding))
        levelLayoutParams.horizontalGravity = 0.5f
        levelLayoutParams.verticalGravity = 0.5f
        levelView.layoutParams = levelLayoutParams
        levelView.listener = this
        addView(levelView)

        // Add slice preview
        slicePreviewView.layoutParams = UniLayoutParams(UniLayoutParams.MATCH_PARENT, UniLayoutParams.MATCH_PARENT)
        slicePreviewView.color = ContextCompat.getColor(context, R.color.slicePreviewLine)
        addView(slicePreviewView)
    }


    // --
    // Sprites
    // --

    fun addSprite(sprite: Sprite) {
        levelView.addSprite(sprite)
    }

    fun clearSprites() {
        levelView.clearSprites()
    }


    // --
    // Slicing
    // --

    fun slice(vector: Vector, restrictCanvasIndices: List<Int>? = null) {
        levelView.slice(vector, restrictCanvasIndices)
        if (levelView.cleared()) {
            clearEvent?.let {
                eventObserver?.observedEvent(it, this)
            }
        }
    }

    fun resetSlices() {
        levelView.resetSlices()
    }


    // --
    // Configurable values
    // --

    var clearEvent: AppEvent? = null
    var lethalHitEvents = listOf<AppEvent>()

    var levelWidth: Float = 1f
        set(levelWidth) {
            field = levelWidth
            levelView.levelWidth = levelWidth
        }

    var levelHeight: Float = 1f
        set(levelHeight) {
            field = levelHeight
            levelView.levelHeight = levelHeight
        }

    var sliceWidth: Float = 0f
        set(sliceWidth) {
            field = sliceWidth
            levelView.sliceWidth = sliceWidth
        }

    var backgroundImage: ImageSource?
        get() = levelView.backgroundImage
        set(backgroundImage) {
            levelView.backgroundImage = backgroundImage
        }

    var requireClearRate: Int
        get() = levelView.requireClearRate
        set(requireClearRate) {
            levelView.requireClearRate = requireClearRate
        }

    var fps: Int
        get() = levelView.fps
        set(fps) {
            levelView.fps = fps
        }

    var drawPhysicsBoundaries: Boolean
        get() = levelView.drawPhysicsBoundaries
        set(drawPhysicsBoundaries) {
            levelView.drawPhysicsBoundaries = drawPhysicsBoundaries
        }


    // --
    // Level view listener
    // --

    override fun onLethalHit() {
        currentSlice = null
        dragStart = null
        dragEnd = null
        slicePreviewView.start = null
        slicePreviewView.end = null
        levelView.setSliceVector(null)
        for (event in lethalHitEvents) {
            eventObserver?.observedEvent(event, this)
        }
    }


    // --
    // Interaction
    // --

    @SuppressLint("ClickableViewAccessibility")
    override fun onTouchEvent(event: MotionEvent?): Boolean {
        if (event != null) {
            when (event.action) {
                // Touch start
                MotionEvent.ACTION_DOWN, MotionEvent.ACTION_POINTER_DOWN -> {
                    if (!levelView.cleared() && dragStart == null && event.pointerCount > 0) {
                        dragStart = PointF(event.getX(0), event.getY(0))
                        dragEnd = dragStart
                        dragPointerId = event.getPointerId(0)
                    }
                    return true
                }

                // Touch move
                MotionEvent.ACTION_MOVE -> {
                    if (dragStart != null && dragEnd != null) {
                        for (i in 0 until event.pointerCount) {
                            if (event.getPointerId(i) == dragPointerId) {
                                // Check if a slice can be made
                                dragEnd = PointF(event.getX(i), event.getY(i))
                                val vectorStart = dragStart
                                val vectorEnd = dragEnd
                                if (vectorStart != null && vectorEnd != null) {
                                    val dragVector = Vector(vectorStart, vectorEnd)
                                    if (currentSlice != null || dragVector.distance() >= minimumDragDistance) {
                                        currentSlice = levelView.validateSlice(dragVector, true)
                                    }
                                } else {
                                    currentSlice = null
                                }

                                // Update view
                                val checkCurrentSlice = currentSlice
                                currentSlice?.let {
                                    dragStart = it.vector.start
                                }
                                slicePreviewView.start = if (checkCurrentSlice != null) {
                                    Point(checkCurrentSlice.vector.start.x.toInt(), checkCurrentSlice.vector.start.y.toInt())
                                } else {
                                    null
                                }
                                slicePreviewView.end = if (checkCurrentSlice != null) {
                                    Point(checkCurrentSlice.vector.end.x.toInt(), checkCurrentSlice.vector.end.y.toInt())
                                } else {
                                    null
                                }
                                levelView.setSliceVector(currentSlice?.vector, true)
                                break
                            }
                        }
                        return true
                    }
                }

                // Touch end
                MotionEvent.ACTION_UP, MotionEvent.ACTION_POINTER_UP -> {
                    if (dragStart != null && dragEnd != null) {
                        for (i in 0 until event.pointerCount) {
                            if (event.getPointerId(i) == dragPointerId) {
                                // Update the slice
                                dragEnd = PointF(event.getX(i), event.getY(i))
                                val vectorStart = dragStart
                                val vectorEnd = dragEnd
                                if (vectorStart != null && vectorEnd != null) {
                                    val dragVector = Vector(vectorStart, vectorEnd)
                                    if (currentSlice != null || dragVector.distance() >= minimumDragDistance) {
                                        currentSlice = levelView.validateSlice(dragVector, true)
                                    }
                                } else {
                                    currentSlice = null
                                }

                                // Apply slice if possible
                                currentSlice?.let {
                                    val transformedVector = levelView.transformedSliceVector(it.vector)
                                    if (transformedVector.isValid() && levelView.setSliceVector(transformedVector)) {
                                        slice(transformedVector, it.canvasIndices)
                                    }
                                }

                                // Reset dragging state
                                currentSlice = null
                                dragStart = null
                                dragEnd = null
                                slicePreviewView.start = null
                                slicePreviewView.end = null
                                levelView.setSliceVector(null)
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
