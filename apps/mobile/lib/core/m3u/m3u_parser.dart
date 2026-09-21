import 'dart:convert';

import 'package:flutter/foundation.dart';

/// One `#EXTINF` entry of an M3U playlist.
@immutable
class M3uEntry {
  const M3uEntry({
    required this.title,
    required this.url,
    this.tvgId,
    this.tvgName,
    this.tvgLogo,
    this.group,
    this.duration = -1,
    this.attributes = const {},
  });

  final String title;
  final String url;
  final String? tvgId;
  final String? tvgName;
  final String? tvgLogo;
  final String? group;
  final double duration;
  final Map<String, String> attributes;

  bool get hasCatchup => attributes.containsKey('catchup') || attributes.containsKey('catchup-days');

  int get catchupDays => int.tryParse(attributes['catchup-days'] ?? '') ?? 0;
}

@immutable
class M3uPlaylist {
  const M3uPlaylist({required this.entries, this.epgUrl});

  final List<M3uEntry> entries;

  /// `url-tvg` / `x-tvg-url` header attribute.
  final String? epgUrl;
}

class M3uFormatException implements Exception {
  const M3uFormatException(this.message);
  final String message;
  @override
  String toString() => 'M3uFormatException: $message';
}

final _attrPattern = RegExp(r'([A-Za-z0-9\-_]+)=("([^"]*)"|([^\s,]+))');

/// Parses a full M3U/M3U8 playlist text (lenient with real-world provider files).
M3uPlaylist parseM3u(String content) {
  final lines = const LineSplitter().convert(content.replaceFirst('\uFEFF', ''));
  if (lines.isEmpty) throw const M3uFormatException('Empty playlist');

  String? epgUrl;
  final entries = <M3uEntry>[];
  var sawHeader = false;

  String? pendingInfo;
  String? pendingGroup;

  for (final raw in lines) {
    final line = raw.trim();
    if (line.isEmpty) continue;

    if (line.startsWith('#EXTM3U')) {
      sawHeader = true;
      final attrs = _parseAttributes(line);
      epgUrl = attrs['url-tvg'] ?? attrs['x-tvg-url'] ?? attrs['tvg-url'];
      continue;
    }
    if (line.startsWith('#EXTINF')) {
      pendingInfo = line;
      continue;
    }
    if (line.startsWith('#EXTGRP:')) {
      pendingGroup = line.substring('#EXTGRP:'.length).trim();
      continue;
    }
    if (line.startsWith('#')) continue;

    // Any non-comment line is a URL for the pending #EXTINF (or a bare URL).
    if (pendingInfo != null) {
      entries.add(_buildEntry(pendingInfo, line, fallbackGroup: pendingGroup));
    } else if (sawHeader || line.contains('://')) {
      entries.add(M3uEntry(title: line, url: line, group: pendingGroup));
    }
    pendingInfo = null;
    pendingGroup = null;
  }

  if (!sawHeader && entries.isEmpty) {
    throw const M3uFormatException('Missing #EXTM3U header');
  }
  return M3uPlaylist(entries: entries, epgUrl: epgUrl);
}

M3uEntry _buildEntry(String info, String url, {String? fallbackGroup}) {
  // #EXTINF:-1 tvg-id="x" group-title="y",Title
  final body = info.substring('#EXTINF:'.length);
  final commaIndex = _titleCommaIndex(body);
  final head = commaIndex >= 0 ? body.substring(0, commaIndex) : body;
  final title = commaIndex >= 0 ? body.substring(commaIndex + 1).trim() : '';

  final durationMatch = RegExp(r'^\s*(-?\d+(\.\d+)?)').firstMatch(head);
  final duration = durationMatch != null ? double.tryParse(durationMatch.group(1)!) ?? -1 : -1.0;
  final attrs = _parseAttributes(head);

  return M3uEntry(
    title: title.isNotEmpty ? title : (attrs['tvg-name'] ?? url),
    url: url,
    tvgId: _nonEmpty(attrs['tvg-id']),
    tvgName: _nonEmpty(attrs['tvg-name']),
    tvgLogo: _nonEmpty(attrs['tvg-logo']),
    group: _nonEmpty(attrs['group-title']) ?? fallbackGroup,
    duration: duration,
    attributes: attrs,
  );
}

/// Index of the comma separating attributes from the title, ignoring commas inside quotes.
int _titleCommaIndex(String body) {
  var inQuotes = false;
  for (var i = 0; i < body.length; i++) {
    final c = body[i];
    if (c == '"') inQuotes = !inQuotes;
    if (c == ',' && !inQuotes) return i;
  }
  return -1;
}

Map<String, String> _parseAttributes(String s) {
  final map = <String, String>{};
  for (final m in _attrPattern.allMatches(s)) {
    map[m.group(1)!.toLowerCase()] = (m.group(3) ?? m.group(4) ?? '').trim();
  }
  return map;
}

String? _nonEmpty(String? s) => (s == null || s.isEmpty) ? null : s;

// ---------------------------------------------------------------------------
// Classification helpers

enum M3uEntryKind { live, vod, series }

final _videoExtensions = RegExp(r'\.(mp4|mkv|avi|mov|wmv|flv|webm|m4v|mpg|mpeg)(\?.*)?$', caseSensitive: false);
final _seriesPattern = RegExp(r'^(.*?)[\s\-_.]*S(\d{1,2})\s*E(\d{1,3})\b', caseSensitive: false);
final _altSeriesPattern = RegExp(r'^(.*?)[\s\-_.]*(\d{1,2})x(\d{1,3})\b', caseSensitive: false);

/// Heuristic classification used when a provider ships everything in a single M3U.
M3uEntryKind classifyEntry(M3uEntry e) {
  final url = e.url.toLowerCase();
  if (url.contains('/series/') || parseSeriesTitle(e.title) != null) return M3uEntryKind.series;
  if (url.contains('/movie/') || _videoExtensions.hasMatch(url)) return M3uEntryKind.vod;
  return M3uEntryKind.live;
}

@immutable
class SeriesTitle {
  const SeriesTitle(this.series, this.season, this.episode);
  final String series;
  final int season;
  final int episode;
}

/// `Show Name S01 E02` / `Show Name 1x02` → series, season, episode.
SeriesTitle? parseSeriesTitle(String title) {
  final m = _seriesPattern.firstMatch(title) ?? _altSeriesPattern.firstMatch(title);
  if (m == null) return null;
  final name = m.group(1)!.trim().replaceAll(RegExp(r'[\-_:]+$'), '').trim();
  if (name.isEmpty) return null;
  return SeriesTitle(name, int.parse(m.group(2)!), int.parse(m.group(3)!));
}
