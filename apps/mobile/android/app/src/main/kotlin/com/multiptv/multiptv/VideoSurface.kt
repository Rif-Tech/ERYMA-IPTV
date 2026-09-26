package com.multiptv.multiptv

import android.content.Context
import android.graphics.Color
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.Gravity
import android.view.SurfaceHolder
import android.view.SurfaceView
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import kotlin.math.max
import kotlin.math.min
import kotlin.math.roundToInt

class VideoSurfaceFactory(private val messenger: BinaryMessenger) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(context: Context, viewId: Int, args: Any?): PlatformView = VideoSurface(context, messenger, viewId)

    companion object {
        const val VIEW_TYPE = "multiptv/video_surface"
    }
}

/**
 * A real SurfaceView for mpv's picture (its `wid`) instead of media_kit's Flutter texture: the
 * decoder then renders through the platform's video path, like the platform players do. On
 * Amlogic boxes that is the video layer: hardware deinterlacing, BT.2020/HDR handled by the display
 * pipeline and frames paced by the compositor, none of which a GPU texture gets.
 *
 * Dart side: `NativeVideoSurface`. Channel `multiptv/video_surface_<id>`:
 * - to Dart, `surface` {wid, width, height} whenever the surface appears, changes or goes (wid 0);
 * - from Dart, `layout` {width, height, fit}: the video's display size and the fit setting.
 */
class VideoSurface(context: Context, messenger: BinaryMessenger, id: Int) : PlatformView, SurfaceHolder.Callback {
    private val channel = MethodChannel(messenger, "multiptv/video_surface_$id")
    private val surfaceView = SurfaceView(context).apply {
        isFocusable = false
        isFocusableInTouchMode = false
    }
    private val container = FrameLayout(context).apply {
        setBackgroundColor(Color.BLACK)
        // The remote belongs to Flutter: nothing here may take the Android focus.
        isFocusable = false
        descendantFocusability = ViewGroup.FOCUS_BLOCK_DESCENDANTS
    }
    private var wid = 0L
    private var videoWidth = 0
    private var videoHeight = 0
    private var fit = "contain"

    init {
        container.addView(surfaceView, FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT, Gravity.CENTER))
        container.addOnLayoutChangeListener { _, left, top, right, bottom, oldLeft, oldTop, oldRight, oldBottom ->
            if (right - left != oldRight - oldLeft || bottom - top != oldBottom - oldTop) container.post { applyLayout() }
        }
        surfaceView.holder.addCallback(this)
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "layout" -> {
                    videoWidth = call.argument<Int>("width") ?: 0
                    videoHeight = call.argument<Int>("height") ?: 0
                    fit = call.argument<String>("fit") ?: "contain"
                    applyLayout()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun getView(): View = container

    override fun dispose() {
        channel.setMethodCallHandler(null)
        surfaceView.holder.removeCallback(this)
        releaseLater(wid)
        wid = 0
    }

    /** MediaCodec scales its output to the whole surface: size the view to the video's shape. */
    private fun applyLayout() {
        val cw = container.width
        val ch = container.height
        val params = if (cw <= 0 || ch <= 0 || videoWidth <= 0 || videoHeight <= 0 || fit == "fill") {
            FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT, Gravity.CENTER)
        } else {
            val scaleX = cw.toDouble() / videoWidth
            val scaleY = ch.toDouble() / videoHeight
            val scale = if (fit == "cover") max(scaleX, scaleY) else min(scaleX, scaleY)
            FrameLayout.LayoutParams((videoWidth * scale).roundToInt(), (videoHeight * scale).roundToInt(), Gravity.CENTER)
        }
        surfaceView.layoutParams = params
    }

    override fun surfaceCreated(holder: SurfaceHolder) {
        wid = newGlobalRef(holder.surface)
    }

    override fun surfaceChanged(holder: SurfaceHolder, format: Int, width: Int, height: Int) {
        channel.invokeMethod("surface", mapOf("wid" to wid, "width" to width, "height" to height))
    }

    override fun surfaceDestroyed(holder: SurfaceHolder) {
        channel.invokeMethod("surface", mapOf("wid" to 0L, "width" to 0, "height" to 0))
        releaseLater(wid)
        wid = 0
    }

    private companion object {
        const val TAG = "VideoSurface"
        val handler = Handler(Looper.getMainLooper())

        // mpv wants the Surface as a JNI global reference; media_kit's helper (bundled by
        // media_kit_libs_android_video) makes them, the same way media_kit_video's VideoOutput does.
        private val helper by lazy { Class.forName("com.alexmercerind.mediakitandroidhelper.MediaKitAndroidHelper") }
        private val newRef by lazy { helper.getDeclaredMethod("newGlobalObjectRef", Any::class.java).apply { isAccessible = true } }
        private val deleteRef by lazy { helper.getDeclaredMethod("deleteGlobalObjectRef", Long::class.javaPrimitiveType).apply { isAccessible = true } }

        fun newGlobalRef(surface: Any): Long = try {
            newRef.invoke(null, surface) as Long
        } catch (e: Throwable) {
            Log.e(TAG, "newGlobalObjectRef", e)
            0L
        }

        /** mpv may still hold the surface for a moment after Dart detached it: release it later. */
        fun releaseLater(ref: Long) {
            if (ref == 0L) return
            handler.postDelayed({
                try {
                    deleteRef.invoke(null, ref)
                } catch (e: Throwable) {
                    Log.e(TAG, "deleteGlobalObjectRef", e)
                }
            }, 5000)
        }
    }
}
