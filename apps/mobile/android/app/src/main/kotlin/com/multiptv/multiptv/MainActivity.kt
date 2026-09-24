package com.multiptv.multiptv

import android.app.PictureInPictureParams
import android.os.Build
import android.os.StatFs
import android.util.Rational
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.renderer.FlutterRenderer
import io.flutter.plugin.common.MethodChannel

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
                else -> result.notImplemented()
            }
        }
    }
}
