import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Disk cache for posters/backdrops. The default manager keeps 200 files for 30 days; IPTV
/// catalogues show thousands of posters, so allow more objects but expire them sooner.
class ArtworkCache {
  ArtworkCache._();

  static const key = 'multiptv_art';

  static final CacheManager instance = CacheManager(
    Config(
      key,
      stalePeriod: const Duration(days: 7),
      maxNrOfCacheObjects: 2000,
    ),
  );
}
