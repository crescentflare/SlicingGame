package com.crescentflare.slicinggame.page.activities

import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.os.Bundle
import android.view.View
import androidx.appcompat.app.AppCompatActivity
import com.crescentflare.slicinggame.components.utility.ViewletUtil
import com.crescentflare.slicinggame.page.storage.PageLoader

/**
 * Activity: a generic activity
 */
class PageActivity : AppCompatActivity() {

    // --
    // Statics: new instance
    // --

    companion object {

        private const val pageParam = "page"
        private const val defaultPage = "game.json"

        fun newInstance(context: Context, pageJson: String): Intent {
            val intent = Intent(context, PageActivity::class.java)
            intent.putExtra(pageParam, pageJson)
            return intent
        }

    }


    // --
    // Initialization
    // --

    override fun onCreate(savedInstanceState: Bundle?) {
        // Set initial content view
        super.onCreate(savedInstanceState)
        val view = View(this)
        view.setBackgroundColor(Color.GREEN)
        setContentView(view)

        // Load page
        val pageLoader = PageLoader(this, intent.getStringExtra(pageParam) ?: defaultPage)
        pageLoader.load { page, _ ->
            page?.layout?.let { layout ->
                ViewletUtil.assertInflateOn(view, layout)
            }?:run {
                view.setBackgroundColor(Color.RED)
            }
        }
    }

}
