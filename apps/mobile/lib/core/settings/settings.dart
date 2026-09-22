import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/theme.dart';

enum LiveFormat { ts, m3u8 }

enum AutoUpdate { never, daily, always }

enum ContentLayout { grid, list }

enum SortOrder { defaultOrder, az, za, added, rating }

enum VideoFit { contain, cover, fill }

/// Android video path. `direct` decodes straight into the surface (mediacodec_embed), which is
/// what low-end TV boxes need; `compat` keeps mpv's GPU renderer with software fallback.
enum VideoDecoder { auto, direct, compat }

/// Lighter visuals (no blur/shimmer, shorter fades, smaller caches) for weak hardware.
enum PerformanceMode { auto, on, off }

/// Where the home hero ("À la une") takes its content from.
enum FeaturedSource { curated, popular, tmdb }

@immutable
class AppSettings {
  const AppSettings({
    this.locale,
    this.themeMode = AppThemeMode.dark,
    this.liveFormat = LiveFormat.ts,
    this.autoUpdate = AutoUpdate.daily,
    this.layout = ContentLayout.grid,
    this.sortOrder = SortOrder.defaultOrder,
    this.videoFit = VideoFit.contain,
    this.videoDecoder = VideoDecoder.auto,
    this.performanceMode = PerformanceMode.auto,
    this.subtitleScale = 1.0,
    this.subtitleColor = 0xFFFFFFFF,
    this.subtitleBackground = false,
    this.use24hClock = true,
    this.featuredSource = FeaturedSource.curated,
    this.parentalPin,
    this.activePlaylistId,
    this.activeProfileId,
  });

  final Locale? locale;
  final AppThemeMode themeMode;
  final LiveFormat liveFormat;
  final AutoUpdate autoUpdate;
  final ContentLayout layout;
  final SortOrder sortOrder;
  final VideoFit videoFit;
  final VideoDecoder videoDecoder;
  final PerformanceMode performanceMode;
  final double subtitleScale;
  final int subtitleColor;
  final bool subtitleBackground;
  final bool use24hClock;
  final FeaturedSource featuredSource;
  final String? parentalPin;
  final String? activePlaylistId;

  /// Viewer profile (server id) whose history/favourites are shown; null until picked.
  final String? activeProfileId;

  bool get hasParentalPin => parentalPin != null && parentalPin!.isNotEmpty;

  AppSettings copyWith({
    Locale? locale,
    bool clearLocale = false,
    AppThemeMode? themeMode,
    LiveFormat? liveFormat,
    AutoUpdate? autoUpdate,
    ContentLayout? layout,
    SortOrder? sortOrder,
    VideoFit? videoFit,
    VideoDecoder? videoDecoder,
    PerformanceMode? performanceMode,
    double? subtitleScale,
    int? subtitleColor,
    bool? subtitleBackground,
    bool? use24hClock,
    FeaturedSource? featuredSource,
    String? parentalPin,
    bool clearParentalPin = false,
    String? activePlaylistId,
    bool clearActivePlaylist = false,
    String? activeProfileId,
    bool clearActiveProfile = false,
  }) =>
      AppSettings(
        locale: clearLocale ? null : (locale ?? this.locale),
        themeMode: themeMode ?? this.themeMode,
        liveFormat: liveFormat ?? this.liveFormat,
        autoUpdate: autoUpdate ?? this.autoUpdate,
        layout: layout ?? this.layout,
        sortOrder: sortOrder ?? this.sortOrder,
        videoFit: videoFit ?? this.videoFit,
        videoDecoder: videoDecoder ?? this.videoDecoder,
        performanceMode: performanceMode ?? this.performanceMode,
        subtitleScale: subtitleScale ?? this.subtitleScale,
        subtitleColor: subtitleColor ?? this.subtitleColor,
        subtitleBackground: subtitleBackground ?? this.subtitleBackground,
        use24hClock: use24hClock ?? this.use24hClock,
        featuredSource: featuredSource ?? this.featuredSource,
        parentalPin: clearParentalPin ? null : (parentalPin ?? this.parentalPin),
        activePlaylistId: clearActivePlaylist ? null : (activePlaylistId ?? this.activePlaylistId),
        activeProfileId: clearActiveProfile ? null : (activeProfileId ?? this.activeProfileId),
      );
}

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Override in main()');
});

class SettingsNotifier extends Notifier<AppSettings> {
  late SharedPreferences _prefs;

  @override
  AppSettings build() {
    _prefs = ref.watch(sharedPreferencesProvider);
    T enumOf<T extends Enum>(List<T> values, String key, T fallback) {
      final v = _prefs.getString(key);
      return values.firstWhere((e) => e.name == v, orElse: () => fallback);
    }

    final localeCode = _prefs.getString('locale');
    return AppSettings(
      locale: localeCode == null ? null : Locale(localeCode),
      // Light/system themes were removed; anything unknown falls back to dark.
      themeMode: enumOf(AppThemeMode.values, 'themeMode', AppThemeMode.dark),
      liveFormat: enumOf(LiveFormat.values, 'liveFormat', LiveFormat.ts),
      autoUpdate: enumOf(AutoUpdate.values, 'autoUpdate', AutoUpdate.daily),
      layout: enumOf(ContentLayout.values, 'layout', ContentLayout.grid),
      sortOrder: enumOf(SortOrder.values, 'sortOrder', SortOrder.defaultOrder),
      videoFit: enumOf(VideoFit.values, 'videoFit', VideoFit.contain),
      videoDecoder: enumOf(VideoDecoder.values, 'videoDecoder', VideoDecoder.auto),
      performanceMode: enumOf(PerformanceMode.values, 'performanceMode', PerformanceMode.auto),
      subtitleScale: _prefs.getDouble('subtitleScale') ?? 1.0,
      subtitleColor: _prefs.getInt('subtitleColor') ?? 0xFFFFFFFF,
      subtitleBackground: _prefs.getBool('subtitleBackground') ?? false,
      use24hClock: _prefs.getBool('use24hClock') ?? true,
      featuredSource: enumOf(FeaturedSource.values, 'featuredSource', FeaturedSource.curated),
      parentalPin: _prefs.getString('parentalPin'),
      activePlaylistId: _prefs.getString('activePlaylistId'),
      activeProfileId: _prefs.getString('activeProfileId'),
    );
  }

  Future<void> update(AppSettings next) async {
    state = next;
    await _persist(next);
  }

  Future<void> setLocale(Locale? locale) => update(state.copyWith(locale: locale, clearLocale: locale == null));
  Future<void> setThemeMode(AppThemeMode m) => update(state.copyWith(themeMode: m));
  Future<void> setLiveFormat(LiveFormat f) => update(state.copyWith(liveFormat: f));
  Future<void> setAutoUpdate(AutoUpdate a) => update(state.copyWith(autoUpdate: a));
  Future<void> setLayout(ContentLayout l) => update(state.copyWith(layout: l));
  Future<void> setSortOrder(SortOrder s) => update(state.copyWith(sortOrder: s));
  Future<void> setVideoFit(VideoFit f) => update(state.copyWith(videoFit: f));
  Future<void> setVideoDecoder(VideoDecoder d) => update(state.copyWith(videoDecoder: d));
  Future<void> setPerformanceMode(PerformanceMode m) => update(state.copyWith(performanceMode: m));
  Future<void> setSubtitleScale(double s) => update(state.copyWith(subtitleScale: s));
  Future<void> setSubtitleColor(int c) => update(state.copyWith(subtitleColor: c));
  Future<void> setSubtitleBackground(bool b) => update(state.copyWith(subtitleBackground: b));
  Future<void> setUse24hClock(bool b) => update(state.copyWith(use24hClock: b));
  Future<void> setFeaturedSource(FeaturedSource s) => update(state.copyWith(featuredSource: s));
  Future<void> setParentalPin(String? pin) =>
      update(state.copyWith(parentalPin: pin, clearParentalPin: pin == null || pin.isEmpty));
  Future<void> setActivePlaylistId(String? id) =>
      update(state.copyWith(activePlaylistId: id, clearActivePlaylist: id == null));
  Future<void> setActiveProfileId(String? id) =>
      update(state.copyWith(activeProfileId: id, clearActiveProfile: id == null));

  Future<void> _persist(AppSettings s) async {
    Future<void> put(String key, Object? value) async {
      if (value == null) {
        await _prefs.remove(key);
      } else if (value is String) {
        await _prefs.setString(key, value);
      } else if (value is bool) {
        await _prefs.setBool(key, value);
      } else if (value is int) {
        await _prefs.setInt(key, value);
      } else if (value is double) {
        await _prefs.setDouble(key, value);
      }
    }

    await put('locale', s.locale?.languageCode);
    await put('themeMode', s.themeMode.name);
    await put('liveFormat', s.liveFormat.name);
    await put('autoUpdate', s.autoUpdate.name);
    await put('layout', s.layout.name);
    await put('sortOrder', s.sortOrder.name);
    await put('videoFit', s.videoFit.name);
    await put('videoDecoder', s.videoDecoder.name);
    await put('performanceMode', s.performanceMode.name);
    await put('subtitleScale', s.subtitleScale);
    await put('subtitleColor', s.subtitleColor);
    await put('subtitleBackground', s.subtitleBackground);
    await put('use24hClock', s.use24hClock);
    await put('featuredSource', s.featuredSource.name);
    await put('parentalPin', s.parentalPin);
    await put('activePlaylistId', s.activePlaylistId);
    await put('activeProfileId', s.activeProfileId);
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);
