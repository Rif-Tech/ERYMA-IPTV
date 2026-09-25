import 'package:flutter_test/flutter_test.dart';
import 'package:multiptv/core/log/remote_key_tracker.dart';

void main() {
  group('RemoteKeyTracker.leftRow', () {
    test('moving inside a shelf is not a row change', () {
      expect(RemoteKeyTracker.leftRow('home/new-movies/h#3', 'home/new-movies/h#4'), isFalse);
    });

    test('leaving a shelf sideways is a row change', () {
      expect(RemoteKeyTracker.leftRow('home/new-movies/h#0', 'home/new-series/h#2'), isTrue);
      expect(RemoteKeyTracker.leftRow('search/channels/h#5', 'tab/search'), isTrue);
    });

    test('categories rail ↔ content grid is the intended layout', () {
      expect(RemoteKeyTracker.leftRow('live/categories/v#2', 'live/content/v#0'), isFalse);
      expect(RemoteKeyTracker.leftRow('movies/content/v#8', 'movies/categories/v#1'), isFalse);
    });

    test('button groups and untagged nodes are ignored', () {
      expect(RemoteKeyTracker.leftRow('home/hero/play', 'home/hero/info'), isFalse);
      expect(RemoteKeyTracker.leftRow('node:InkWell', 'scope:FocusScope'), isFalse);
    });
  });
}
