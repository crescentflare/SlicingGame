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
import com.crescentflare.slicinggame.infrastructure.physics.Physics
import com.crescentflare.slicinggame.sprites.core.Sprite
import com.crescentflare.slicinggame.sprites.core.SpriteCanvas
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.GlobalScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlin.math.max


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

                    // Apply update frames per second
                    obj.fps = mapUtil.optionalInteger(attributes, "fps", 60)

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

    private val physics = Physics()
    private val sprites = mutableListOf<Sprite>()
    private val paint = Paint(Paint.ANTI_ALIAS_FLAG)
    private val spriteCanvas = SpriteCanvas(paint)
    private var updateScheduled = false
    private var lastTimeMillis = System.currentTimeMillis()
    private var timeCorrection = 1


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
    // Sprites
    // --

    fun addSprite(sprite: Sprite) {
        sprites.add(sprite)
        physics.registerObject(sprite)
    }

    fun clearSprites() {
        sprites.clear()
        physics.clearObjects()
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

    var fps = 60


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
        // Draw sprites
        canvas?.let {
            it.clipRect(0, 0, width, height)
            spriteCanvas.prepare(it, width.toFloat(), height.toFloat(), gridWidth, gridHeight)
            sprites.forEach { sprite ->
                sprite.draw(spriteCanvas)
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
