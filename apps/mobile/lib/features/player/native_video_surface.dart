import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../core/settings/settings.dart';

/// mpv's picture on a real Android SurfaceView ([VideoOutput.native], `VideoSurface.kt`) instead
/// of media_kit's Flutter texture. [onSurface] receives the surface to hand to mpv (`wid`, a JNI
/// global reference) whenever it appears or changes, and `wid` 0 when it goes.
///
/// Hybrid composition: the view sits in Android's own hierarchy (a SurfaceView cannot live in a
/// texture), Flutter drawing the controls above it.
class NativeVideoSurface extends StatefulWidget {
  const NativeVideoSurface({super.key, required this.onSurface, required this.videoWidth, required this.videoHeight, required this.fit});

  final void Function(int wid, int width, int height) onSurface;
  final int? videoWidth;
  final int? videoHeight;
  final VideoFit fit;

  @override
  State<NativeVideoSurface> createState() => _NativeVideoSurfaceState();
}

class _NativeVideoSurfaceState extends State<NativeVideoSurface> {
  static const _viewType = 'multiptv/video_surface';
  MethodChannel? _channel;

  void _attach(int id) {
    final channel = MethodChannel('multiptv/video_surface_$id');
    channel.setMethodCallHandler((call) async {
      if (call.method != 'surface' || !mounted) return;
      final args = Map<String, Object?>.from(call.arguments as Map);
      int value(String key) => (args[key] as num?)?.toInt() ?? 0;
      widget.onSurface(value('wid'), value('width'), value('height'));
    });
    _channel = channel;
    _layout();
  }

  void _layout() {
    final channel = _channel;
    if (channel == null) return;
    channel.invokeMethod('layout', {'width': widget.videoWidth ?? 0, 'height': widget.videoHeight ?? 0, 'fit': widget.fit.name}).catchError((Object e) {
      debugPrint('video surface layout failed: $e');
    });
  }

  @override
  void didUpdateWidget(NativeVideoSurface old) {
    super.didUpdateWidget(old);
    if (old.videoWidth != widget.videoWidth || old.videoHeight != widget.videoHeight || old.fit != widget.fit) _layout();
  }

  @override
  void dispose() {
    _channel?.setMethodCallHandler(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The remote drives Flutter's controls: the video itself is never a focus target.
    return ExcludeFocus(
      child: PlatformViewLink(
        viewType: _viewType,
        surfaceFactory: (context, controller) => AndroidViewSurface(
          controller: controller as AndroidViewController,
          gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
          hitTestBehavior: PlatformViewHitTestBehavior.transparent,
        ),
        onCreatePlatformView: (params) {
          final controller = PlatformViewsService.initExpensiveAndroidView(
            id: params.id,
            viewType: _viewType,
            layoutDirection: TextDirection.ltr,
            creationParamsCodec: const StandardMessageCodec(),
          )
            ..addOnPlatformViewCreatedListener(params.onPlatformViewCreated)
            ..addOnPlatformViewCreatedListener(_attach);
          controller.create();
          return controller;
        },
      ),
    );
  }
}
