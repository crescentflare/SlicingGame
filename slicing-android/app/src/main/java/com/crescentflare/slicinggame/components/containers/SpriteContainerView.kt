package com.crescentflare.slicinggame.components.containers

import android.annotation.TargetApi
import android.content.Context
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.PointF
import android.os.Build
import android.util.AttributeSet
import com.crescentflare.jsoninflator.JsonInflatable
import com.crescentflare.jsoninflator.binder.InflatorBinder
import com.crescentflare.jsoninflator.utility.InflatorMapUtil
import com.crescentflare.slicinggame.components.utility.ViewletUtil
import com.crescentflare.slicinggame.infrastructure.geometry.Polygon
import com.crescentflare.slicinggame.infrastructure.geometry.Vector
import com.crescentflare.slicinggame.infrastructure.physics.Physics
import com.crescentflare.slicinggame.infrastructure.physics.PhysicsBoundary
import com.crescentflare.slicinggame.sprites.core.Sprite
import com.crescentflare.slicinggame.sprites.core.SpriteCanvas
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.GlobalScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import java.lang.ref.WeakReference
import kotlin.math.PI
import kotlin.math.atan2
import kotlin.math.max


/**
 * Container view: provides a container for managing sprites
 */
open class SpriteContainerView : FrameContainerView, Physics.Listener {

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
                    obj.sliceWidth = mapUtil.optionalFloat(attributes, "sliceWidth", 0f)

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

    var physicsListener: Physics.Listener?
        get() = physicsListenerReference?.get()
        set(physicsListener) {
            physicsListenerReference = if (physicsListener != null) {
                WeakReference(physicsListener)
            } else {
                null
            }
        }

    private val physics = Physics()
    private val sprites = mutableListOf<Sprite>()
    private var collisionBoundaries = mutableListOf<PhysicsBoundary>()
    private var sliceVectorBoundary: PhysicsBoundary? = null
    private val paint = Paint(Paint.ANTI_ALIAS_FLAG)
    private val spriteCanvas = SpriteCanvas(paint)
    private var currentSliceVector: Vector? = null
    private var updateScheduled = false
    private var lastTimeMillis = System.currentTimeMillis()
    private var timeCorrection = 1
    private var physicsListenerReference: WeakReference<Physics.Listener>? = null


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
        setWillNotDraw(false)
        physics.listener = this
    }


    // --
    // Sprites
    // --

    fun addSprite(sprite: Sprite) {
        sprites.add(sprite)
        physics.registerObject(sprite)
    }

    fun clearSprites() {
        for (sprite in sprites) {
            physics.unregisterObject(sprite)
        }
        sprites.clear()
    }


    // --
    // Collision boundaries
    // --

    fun addCollisionBoundary(boundary: PhysicsBoundary) {
        collisionBoundaries.add(boundary)
        physics.registerObject(boundary)
    }

    fun addCollisionBoundaries(polygon: Polygon) {
        val boundaryWidth = max(sliceWidth, gridWidth * 0.005f)
        for (vector in polygon.asVectorList()) {
            val offsetVector = vector.perpendicular().unit() * (boundaryWidth / 2)
            val halfDistanceX = vector.x / 2
            val halfDistanceY = vector.y / 2
            val vectorCenterX = vector.start.x + halfDistanceX
            val vectorCenterY = vector.start.y + halfDistanceY
            val centerX = vectorCenterX + offsetVector.x
            val centerY = vectorCenterY + offsetVector.y
            val vectorLength = vector.distance()
            val x = centerX - boundaryWidth / 2
            val y = centerY - vectorLength / 2
            val rotation = atan2(vector.x, vector.y) * 360 / (PI.toFloat() * 2)
            addCollisionBoundary(PhysicsBoundary(x, y, boundaryWidth, vectorLength, -rotation))
        }
    }

    fun clearCollisionBoundaries() {
        for (collisionBoundary in collisionBoundaries) {
            physics.unregisterObject(collisionBoundary)
        }
        collisionBoundaries.clear()
    }


    // --
    // Slicing
    // --

    fun setSliceVector(vector: Vector?): Boolean {
        // First unregister the existing object
        val previousSliceVector = currentSliceVector
        sliceVectorBoundary?.let {
            physics.unregisterObject(it)
        }
        sliceVectorBoundary = null
        currentSliceVector = null

        // Check if it already collides
        vector?.let {
            if (previousSliceVector != null) {
                val intersection = previousSliceVector.intersect(it)
                val polygons = mutableListOf<Polygon>()
                if (intersection != null) {
                    polygons.add(Polygon(listOf(previousSliceVector.start, vector.start, intersection)))
                    polygons.add(Polygon(listOf(previousSliceVector.end, vector.end, intersection)))
                } else {
                    polygons.add(Polygon(listOf(previousSliceVector.start, vector.start, vector.end, previousSliceVector.end)))
                }
                for (polygon in polygons) {
                    val checkPolygon = if (polygon.isClockwise()) polygon else polygon.reversed()
                    if (physics.intersectsSprite(checkPolygon)) {
                        onLethalCollision()
                        return false
                    }
                }
            } else if (physics.intersectsSprite(it)) {
                onLethalCollision()
                return false
            }
        }

        // Add slice boundary
        vector?.let {
            val vectorCenterX = it.start.x + it.x / 2
            val vectorCenterY = it.start.y + it.y / 2
            val width = gridWidth * 0.005f
            val height = it.distance()
            val x = vectorCenterX - width / 2
            val y = vectorCenterY - height / 2
            val rotation = atan2(it.x, it.y) * 360 / (PI.toFloat() * 2)
            val physicsBoundary = PhysicsBoundary(x, y, width, height, -rotation)
            physicsBoundary.lethal = true
            physics.registerObject(physicsBoundary)
            sliceVectorBoundary = physicsBoundary
        }
        currentSliceVector = vector
        return true
    }

    fun spritesOnPolygon(polygon: Polygon): Boolean {
        return physics.intersectsSprite(polygon)
    }

    fun spritesPerSlice(vector: Vector, polygon: Polygon): Int {
        var spriteCount = 0
        sprites.forEach {
            val spriteBounds = it.collisionBounds
            spriteBounds.offset(it.x, it.y)
            val spritePolygon = Polygon(spriteBounds, PointF(it.collisionPivot.x + it.x, it.collisionPivot.y + it.y), it.collisionRotation)
            if (spritePolygon.intersect(polygon)) {
                if (vector.directionOfPoint(PointF(it.x + it.collisionPivot.x, it.y + it.collisionPivot.y)) >= 0) {
                    spriteCount += 1
                }
            }
        }
        return spriteCount
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
            physics.width = gridWidth
        }

    var gridHeight: Float = 1f
        set(gridHeight) {
            val changed = field != gridHeight
            field = gridHeight
            if (changed) {
                requestLayout()
            }
            physics.height = gridHeight
        }

    var sliceWidth = 0f

    var fps = 60

    var drawPhysicsBoundaries = false


    // --
    // Physics listener
    // --

    override fun onLethalCollision() {
        physicsListener?.onLethalCollision()
    }


    // --
    // Movement
    // --

    private fun update(timeDifference: Long) {
        val timeInterval = timeDifference.toFloat() / 1000
        physics.prepareObjects()
        sprites.forEach { sprite ->
            sprite.update(timeInterval, physics)
        }
        invalidate()
    }


    // --
    // Drawing
    // --

    override fun onDraw(canvas: Canvas?) {
        // Draw sprites and optional physics boundaries
        canvas?.let {
            it.clipRect(0, 0, width, height)
            spriteCanvas.prepare(it, width.toFloat(), height.toFloat(), gridWidth, gridHeight)
            sprites.forEach { sprite ->
                sprite.draw(spriteCanvas)
            }
            if (drawPhysicsBoundaries) {
                for (boundary in collisionBoundaries) {
                    spriteCanvas.fillRotatedRect(boundary.x + boundary.collisionPivot.x, boundary.y + boundary.collisionPivot.y, boundary.width, boundary.height, Color.RED, boundary.collisionRotation)
                }
                sliceVectorBoundary?.let { boundary ->
                    spriteCanvas.fillRotatedRect(boundary.x + boundary.collisionPivot.x, boundary.y + boundary.collisionPivot.y, boundary.width, boundary.height, Color.YELLOW, boundary.collisionRotation)
                }
            }
        }

        // Schedule next update
        if (!updateScheduled) {
            val checkTimeMillis = System.currentTimeMillis()
            val delayTime = 1000 / fps - (checkTimeMillis - lastTimeMillis)
            updateScheduled = true
            GlobalScope.launch(Dispatchers.Main) {
                // Delay and try to correct for time lost due to coroutine inaccuracy
                delay(max(1, delayTime - timeCorrection))
                val currentTimeMillis = System.currentTimeMillis()
                if (delayTime >= 1) {
                    val lostTimeMillis = (currentTimeMillis - checkTimeMillis) - delayTime
                    if (lostTimeMillis < -1) {
                        timeCorrection -= 1
                    } else if (lostTimeMillis > 1) {
                        timeCorrection += 1
                    }
                }

                // Continue with the next update
                var difference = currentTimeMillis - lastTimeMillis
                lastTimeMillis = currentTimeMillis
                updateScheduled = false
                if (difference > 1000 / fps * 5) {
                    difference = (1000 / fps * 5).toLong()
                }
                update(difference)
            }
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
