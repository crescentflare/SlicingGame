package com.crescentflare.slicinggame.page.activities

import android.graphics.Color
import android.os.Bundle
import android.view.View
import androidx.appcompat.app.AppCompatActivity

/**
 * Activity: a generic activity
 */
class PageActivity : AppCompatActivity() {

    // --
    // Initialization
    // --

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val view = View(this)
        view.setBackgroundColor(Color.GREEN)
        setContentView(view)
    }

}
