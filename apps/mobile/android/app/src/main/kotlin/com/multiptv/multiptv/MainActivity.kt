package com.multiptv.multiptv

import android.annotation.TargetApi
import android.app.PictureInPictureParams
import android.os.Build
import android.os.StatFs
import android.util.Rational
import android.view.Display
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.renderer.FlutterRenderer
import io.flutter.plugin.common.MethodChannel
import java.util.Locale
import kotlin.math.abs
import kotlin.math.roundToInt

class MainActivity : FlutterActivity() {
    private val channelName = "multiptv/platform"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        // media_kit renders video into a Flutter SurfaceProducer, backed by an ImageReader on
        // Android 10+. Amlogic decoders (Mi Box S gen 2, OMX.amlogic.*) refuse to start on it
        // ("MediaCodec start failed": black screen in direct mode) and the copy path stalls the
        // main thread on its GPU fences (ANR, massive frame drops). Sentry FLUTTER-D/E/5/6.
        // The SurfaceTexture backend is what video on Android used before and works on them.
        FlutterRenderer.debugForceSurfaceProducerGlTextures = true
        super.configureFlutterEngine(flutterEngine)
        // "Native" video output (Réglages → Lecture): mpv renders into a real SurfaceView.
        flutterEngine.platformViewsController.registry.registerViewFactory(
            VideoSurfaceFactory.VIEW_TYPE,
            VideoSurfaceFactory(flutterEngine.dartExecutor.binaryMessenger),
        )
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "statFs" -> {
                    val path = call.argument<String>("path")
                    if (path == null) {
                        result.error("bad_args", "path is required", null)
                        return@setMethodCallHandler
                    }
                    try {
                        val stat = StatFs(path)
                        result.success(
                            mapOf(
                                "freeBytes" to stat.availableBytes,
                                "totalBytes" to stat.totalBytes,
                            ),
                        )
                    } catch (e: Exception) {
                        result.error("statfs_failed", e.message, null)
                    }
                }
                "enterPip" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        val width = call.argument<Int>("width") ?: 16
                        val height = call.argument<Int>("height") ?: 9
                        val params = PictureInPictureParams.Builder()
                            .setAspectRatio(Rational(width, height))
                            .build()
                        result.success(enterPictureInPictureMode(params))
                    } else {
                        result.success(false)
                    }
                }
                "isInPipMode" -> {
                    result.success(
                        Build.VERSION.SDK_INT >= Build.VERSION_CODES.N && isInPictureInPictureMode,
                    )
                }
                "matchFrameRate" -> {
                    val fps = call.argument<Double>("fps")
                    if (fps == null || fps <= 0 || Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
                        result.success(null)
                        return@setMethodCallHandler
                    }
                    val mode = modeFor(fps)
                    if (mode != null) setPreferredMode(mode.modeId)
                    result.success(mode?.refreshRate?.toDouble())
                }
                "resetFrameRate" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) setPreferredMode(0)
                    result.success(null)
                }
                "displayInfo" -> result.success(displayInfo())
                else -> result.notImplemented()
            }
        }
    }

    @Suppress("DEPRECATION")
    private fun currentDisplay(): Display = windowManager.defaultDisplay

    /**
     * Display mode (same resolution) whose refresh rate the content's [fps] divides evenly, so
     * every frame stays on screen for the same number of refreshes: 25/50 fps → 50 Hz, 23.976 fps
     * → 23.976 Hz. Keeps the current mode when it already fits; null when the TV offers none.
     */
    @TargetApi(Build.VERSION_CODES.M)
    private fun modeFor(fps: Double): Display.Mode? {
        val display = currentDisplay()
        val current = display.mode
        fun error(mode: Display.Mode): Double? {
            val multiple = (mode.refreshRate / fps).roundToInt()
            if (multiple !in 1..4 || mode.refreshRate > 61f) return null
            val error = abs(mode.refreshRate / multiple - fps)
            return if (error < 0.06) error else null
        }
        val currentError = error(current)
        if (currentError != null && currentError < 0.01) return current
        return display.supportedModes
            .filter { it.physicalWidth == current.physicalWidth && it.physicalHeight == current.physicalHeight }
            .mapNotNull { mode -> error(mode)?.let { mode to it } }
            // Closest to the content first (23.976 Hz before 24 Hz), then the highest rate (50 Hz
            // before 25 Hz for a 25 fps channel).
            .sortedWith(compareBy<Pair<Display.Mode, Double>> { (it.second * 1000).roundToInt() }.thenByDescending { it.first.refreshRate })
            .firstOrNull()?.first
    }

    /** 0 hands the choice back to the system (the mode used before playback). */
    @TargetApi(Build.VERSION_CODES.M)
    private fun setPreferredMode(modeId: Int) {
        val attributes = window.attributes
        if (attributes.preferredDisplayModeId == modeId) return
        attributes.preferredDisplayModeId = modeId
        window.attributes = attributes
    }

    private fun displayInfo(): Map<String, Any?> {
        val display = currentDisplay()
        val info = mutableMapOf<String, Any?>("refreshRate" to display.refreshRate.toDouble())
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val mode = display.mode
            info["mode"] = "${mode.physicalWidth}x${mode.physicalHeight}@${"%.3f".format(Locale.US, mode.refreshRate)}"
            info["modes"] = display.supportedModes.map { "${it.physicalWidth}x${it.physicalHeight}@${"%.3f".format(Locale.US, it.refreshRate)}" }
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            info["hdr"] = display.hdrCapabilities?.supportedHdrTypes?.map {
                when (it) {
                    Display.HdrCapabilities.HDR_TYPE_DOLBY_VISION -> "dolby_vision"
                    Display.HdrCapabilities.HDR_TYPE_HDR10 -> "hdr10"
                    Display.HdrCapabilities.HDR_TYPE_HLG -> "hlg"
                    else -> "type_$it"
                }
            }
        }
        return info
    }
}
