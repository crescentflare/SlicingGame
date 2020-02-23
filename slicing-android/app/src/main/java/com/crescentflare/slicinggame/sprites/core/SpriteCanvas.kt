package com.crescentflare.slicinggame.sprites.core

import android.graphics.Canvas
import android.graphics.Paint

/**
 * Sprite core: a canvas to easily draw pixel independent sprites
 */
class SpriteCanvas(private val paint: Paint) {

    // --
    // Members
    // --

    private var canvas: Canvas? = null
    private var canvasWidth: Float = 1f
    private var canvasHeight: Float = 1f
    private var gridWidth: Float = 1f
    private var gridHeight: Float = 1f
    private var scaleX: Float = 1f
    private var scaleY: Float = 1f


    // --
    // Initialization
    // --

    init {
        // No implementation
    }

    fun prepare(canvas: Canvas, canvasWidth: Float, canvasHeight: Float, gridWidth: Float, gridHeight: Float) {
        this.canvas = canvas
        this.canvasWidth = canvasWidth
        this.canvasHeight = canvasHeight
        this.gridWidth = gridWidth
        this.gridHeight = gridHeight
        scaleX = if (gridWidth > 0) canvasWidth / gridWidth else 1f
        scaleY = if (gridHeight > 0) canvasHeight / gridHeight else 1f
    }


    // --
    // Drawing shapes
    // --

    fun fillRect(x: Float, y: Float, width: Float, height: Float, color: Int) {
        paint.color = color
        paint.style = Paint.Style.FILL
        canvas?.drawRect(x * scaleX, y * scaleY, (x + width) * scaleX, (y + height) * scaleY, paint)
    }

    fun fillRotatedRect(centerX: Float, centerY: Float, width: Float, height: Float, color: Int, rotation: Float) {
        paint.color = color
        paint.style = Paint.Style.FILL
        canvas?.save()
        canvas?.scale(scaleX, scaleY)
        canvas?.translate(centerX, centerY)
        canvas?.rotate(rotation)
        canvas?.drawRect(-width / 2, -height / 2, width / 2, height / 2, paint)
        canvas?.restore()
    }

}
