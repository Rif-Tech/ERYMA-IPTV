import 'dart:io';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../db/database.dart';
import '../epg/xmltv_parser.dart';
import '../m3u/m3u_parser.dart';
import '../xtream/xtream_client.dart';

enum ImportStage { connecting, live, movies, series, epg, done }

@immutable
class ImportProgress {
  const ImportProgress(this.stage, {this.done = 0, this.total = 0, this.message});
  final ImportStage stage;
  final int done;
  final int total;
  final String? message;
}

class ImportException implements Exception {
  const ImportException(this.message, {this.isAuthError = false});
  final String message;
  final bool isAuthError;
  @override
  String toString() => 'ImportException: $message';
}

/// Loads a playlist's content (channels, VOD, series, EPG) into the local database.
class PlaylistImporter {
  PlaylistImporter(this.db, {Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 20),
              receiveTimeout: const Duration(minutes: 5),
              headers: {'User-Agent': 'MultIPTV/1.0'},
            ));

  final AppDatabase db;
  final Dio _dio;

  static const _batchSize = 500;

  Future<void> import(Playlist playlist, {void Function(ImportProgress)? onProgress}) async {
    final report = onProgress ?? (_) {};
    report(const ImportProgress(ImportStage.connecting));
    switch (playlist.type) {
      case PlaylistType.xtream:
        await _importXtream(playlist, report);
      case PlaylistType.m3u:
        await _importM3u(playlist, report);
    }
    await db.upsertPlaylist(PlaylistsCompanion(
      id: Value(playlist.id),
      name: Value(playlist.name),
      type: Value(playlist.type),
      source: Value(playlist.source),
      url: Value(playlist.url),
      username: Value(playlist.username),
      password: Value(playlist.password),
      epgUrl: Value(playlist.epgUrl),
      isProtected: Value(playlist.isProtected),
      pinCode: Value(playlist.pinCode),
      expiresAt: Value(playlist.expiresAt),
      position: Value(playlist.position),
      lastSyncedAt: Value(DateTime.now()),
    ));
    report(const ImportProgress(ImportStage.done));
  }

  // ---- Xtream -----------------------------------------------------------

  Future<void> _importXtream(Playlist p, void Function(ImportProgress) report) async {
    final creds = XtreamCredentials(baseUrl: p.url, username: p.username ?? '', password: p.password ?? '');
    final client = XtreamClient(creds, dio: _dio);
    final XtreamAccount account;
    try {
      account = await client.login();
    } on XtreamException catch (e) {
      throw ImportException(e.message, isAuthError: e.isAuthError);
    }
    await (db.update(db.playlists)..where((t) => t.id.equals(p.id))).write(PlaylistsCompanion(
      accountInfo: Value(_encodeAccount(account)),
    ));

    try {
      report(const ImportProgress(ImportStage.live));
      final liveCats = await client.liveCategories();
      final live = await client.liveStreams();
      report(ImportProgress(ImportStage.live, total: live.length));

      report(const ImportProgress(ImportStage.movies));
      final vodCats = await client.vodCategories();
      final vod = await client.vodStreams();
      report(ImportProgress(ImportStage.movies, total: vod.length));

      report(const ImportProgress(ImportStage.series));
      final seriesCats = await client.seriesCategories();
      final series = await client.series();
      report(ImportProgress(ImportStage.series, total: series.length));

      await db.transaction(() async {
        await db.clearPlaylistContent(p.id);
        await _insertCategories(p.id, ContentKind.live, liveCats);
        await _insertCategories(p.id, ContentKind.vod, vodCats);
        await _insertCategories(p.id, ContentKind.series, seriesCats);

        await _batched(live, (chunk, offset) => db.batch((b) {
              b.insertAll(db.channels, [
                for (final (i, s) in chunk.indexed)
                  ChannelsCompanion.insert(
                    playlistId: p.id,
                    streamId: s.streamId,
                    name: s.name,
                    logo: Value(s.icon),
                    categoryId: Value(s.categoryId),
                    epgChannelId: Value(s.epgChannelId),
                    number: Value(s.number),
                    tvArchive: Value(s.tvArchive),
                    tvArchiveDuration: Value(s.tvArchiveDuration),
                    position: Value(offset + i),
                  ),
              ]);
            }));

        await _batched(vod, (chunk, offset) => db.batch((b) {
              b.insertAll(db.movies, [
                for (final (i, m) in chunk.indexed)
                  MoviesCompanion.insert(
                    playlistId: p.id,
                    streamId: m.streamId,
                    name: m.name,
                    poster: Value(m.icon),
                    categoryId: Value(m.categoryId),
                    containerExtension: Value(m.containerExtension),
                    rating: Value(m.rating),
                    year: Value(m.year),
                    addedAt: Value(m.addedAt),
                    position: Value(offset + i),
                  ),
              ]);
            }));

        await _batched(series, (chunk, offset) => db.batch((b) {
              b.insertAll(db.seriesItems, [
                for (final (i, s) in chunk.indexed)
                  SeriesItemsCompanion.insert(
                    playlistId: p.id,
                    seriesId: s.seriesId,
                    name: s.name,
                    cover: Value(s.cover),
                    categoryId: Value(s.categoryId),
                    plot: Value(s.plot),
                    rating: Value(s.rating),
                    year: Value(s.year),
                    addedAt: Value(s.lastModified),
                    position: Value(offset + i),
                  ),
              ]);
            }));
      });
    } on XtreamException catch (e) {
      throw ImportException(e.message, isAuthError: e.isAuthError);
    }

    await importEpg(p, url: p.epgUrl ?? creds.xmltvUrl, report: report);
  }

  /// Fetches episodes for one series on demand (Xtream only) and caches them.
  Future<List<Episode>> loadEpisodes(Playlist p, String seriesId) async {
    if (p.type != PlaylistType.xtream) return db.getEpisodes(p.id, seriesId);
    final creds = XtreamCredentials(baseUrl: p.url, username: p.username ?? '', password: p.password ?? '');
    final client = XtreamClient(creds, dio: _dio);
    final XtreamSeriesInfo info;
    try {
      info = await client.seriesInfo(seriesId);
    } on XtreamException catch (e) {
      throw ImportException(e.message, isAuthError: e.isAuthError);
    }
    await db.transaction(() async {
      await (db.delete(db.episodes)..where((e) => e.playlistId.equals(p.id) & e.seriesId.equals(seriesId))).go();
      await db.batch((b) {
        b.insertAll(db.episodes, [
          for (final e in info.episodes)
            EpisodesCompanion.insert(
              playlistId: p.id,
              seriesId: seriesId,
              episodeId: e.id,
              season: e.season,
              episodeNum: e.episodeNum,
              title: e.title,
              containerExtension: Value(e.containerExtension),
              poster: Value(e.poster),
              durationSecs: Value(e.durationSecs),
              plot: Value(e.plot),
              resolution: Value(e.resolution),
            ),
        ]);
      });
      if (info.plot != null) {
        await (db.update(db.seriesItems)..where((s) => s.playlistId.equals(p.id) & s.seriesId.equals(seriesId)))
            .write(SeriesItemsCompanion(plot: Value(info.plot)));
      }
    });
    return db.getEpisodes(p.id, seriesId);
  }

  // ---- M3U --------------------------------------------------------------

  Future<void> _importM3u(Playlist p, void Function(ImportProgress) report) async {
    final String content;
    try {
      content = await _readSource(p.url);
    } on DioException catch (e) {
      throw ImportException(e.message ?? 'Download failed');
    } on FileSystemException catch (e) {
      throw ImportException(e.message);
    }
    final M3uPlaylist parsed;
    try {
      parsed = parseM3u(content);
    } on M3uFormatException catch (e) {
      throw ImportException(content.trim().isEmpty ? 'Server returned an empty playlist' : e.message);
    }
    if (parsed.entries.isEmpty) throw const ImportException('Playlist is empty');

    final liveCats = <String, int>{};
    final vodCats = <String, int>{};
    final seriesCats = <String, int>{};
    final channels = <ChannelsCompanion>[];
    final movies = <MoviesCompanion>[];
    final seriesById = <String, SeriesItemsCompanion>{};
    final episodes = <EpisodesCompanion>[];
    final seenIds = <String>{};

    String catId(Map<String, int> map, String? group) {
      final name = (group == null || group.isEmpty) ? 'Uncategorized' : group;
      return map.putIfAbsent(name, () => map.length).toString();
    }

    String uniqueId(String base) {
      var id = base;
      var n = 1;
      while (!seenIds.add(id)) {
        id = '$base-${n++}';
      }
      return id;
    }

    for (final (index, e) in parsed.entries.indexed) {
      final kind = classifyEntry(e);
      final id = uniqueId(_idForUrl(e.url));
      switch (kind) {
        case M3uEntryKind.live:
          channels.add(ChannelsCompanion.insert(
            playlistId: p.id,
            streamId: id,
            name: e.title,
            logo: Value(e.tvgLogo),
            categoryId: Value(catId(liveCats, e.group)),
            epgChannelId: Value(e.tvgId ?? e.tvgName),
            streamUrl: Value(e.url),
            tvArchive: Value(e.hasCatchup),
            tvArchiveDuration: Value(e.catchupDays),
            position: Value(index),
          ));
        case M3uEntryKind.vod:
          movies.add(MoviesCompanion.insert(
            playlistId: p.id,
            streamId: id,
            name: e.title,
            poster: Value(e.tvgLogo),
            categoryId: Value(catId(vodCats, e.group)),
            streamUrl: Value(e.url),
            position: Value(index),
          ));
        case M3uEntryKind.series:
          final st = parseSeriesTitle(e.title);
          final seriesName = st?.series ?? e.title;
          final seriesId = 'm3u-series-${seriesName.toLowerCase().hashCode.toRadixString(16)}';
          seriesById.putIfAbsent(
            seriesId,
            () => SeriesItemsCompanion.insert(
              playlistId: p.id,
              seriesId: seriesId,
              name: seriesName,
              cover: Value(e.tvgLogo),
              categoryId: Value(catId(seriesCats, e.group)),
              position: Value(index),
            ),
          );
          episodes.add(EpisodesCompanion.insert(
            playlistId: p.id,
            seriesId: seriesId,
            episodeId: id,
            season: st?.season ?? 1,
            episodeNum: st?.episode ?? episodes.length + 1,
            title: e.title,
            streamUrl: Value(e.url),
            poster: Value(e.tvgLogo),
          ));
      }
    }

    report(ImportProgress(ImportStage.live, total: channels.length));
    await db.transaction(() async {
      await db.clearPlaylistContent(p.id);
      for (final (kind, map) in [(ContentKind.live, liveCats), (ContentKind.vod, vodCats), (ContentKind.series, seriesCats)]) {
        await db.batch((b) => b.insertAll(db.categories, [
              for (final entry in map.entries)
                CategoriesCompanion.insert(
                  playlistId: p.id,
                  externalId: entry.value.toString(),
                  kind: kind,
                  name: entry.key,
                  position: Value(entry.value),
                ),
            ]));
      }
      await _batched(channels, (chunk, _) => db.batch((b) => b.insertAll(db.channels, chunk)));
      await _batched(movies, (chunk, _) => db.batch((b) => b.insertAll(db.movies, chunk)));
      await _batched(seriesById.values.toList(), (chunk, _) => db.batch((b) => b.insertAll(db.seriesItems, chunk)));
      await _batched(episodes, (chunk, _) => db.batch((b) => b.insertAll(db.episodes, chunk)));
    });

    final epgUrl = p.epgUrl ?? parsed.epgUrl;
    if (epgUrl != null && epgUrl.isNotEmpty) {
      if (p.epgUrl == null) {
        await (db.update(db.playlists)..where((t) => t.id.equals(p.id))).write(PlaylistsCompanion(epgUrl: Value(epgUrl)));
      }
      await importEpg(p, url: epgUrl, report: report);
    }
  }

  // ---- EPG --------------------------------------------------------------

  Future<void> importEpg(Playlist p, {required String url, void Function(ImportProgress)? report}) async {
    report?.call(const ImportProgress(ImportStage.epg));
    final Stream<List<int>> bytes;
    try {
      if (url.startsWith('file://') || url.startsWith('/')) {
        bytes = File(Uri.parse(url).toFilePath()).openRead();
      } else {
        final res = await _dio.get<ResponseBody>(url, options: Options(responseType: ResponseType.stream));
        bytes = res.data!.stream;
      }
    } catch (_) {
      // EPG is optional: a failure must not invalidate the playlist.
      return;
    }

    final horizon = DateTime.now().subtract(const Duration(days: 2));
    final buffer = <EpgProgramsCompanion>[];
    var count = 0;
    try {
      await db.clearEpg(p.id);
      await for (final prog in XmltvParser().parse(bytes)) {
        if (prog.end.isBefore(horizon)) continue;
        buffer.add(EpgProgramsCompanion.insert(
          playlistId: p.id,
          channelId: prog.channelId,
          start: prog.start,
          end: prog.end,
          title: prog.title,
          description: Value(prog.description),
        ));
        if (buffer.length >= _batchSize) {
          await db.batch((b) => b.insertAll(db.epgPrograms, List.of(buffer)));
          count += buffer.length;
          buffer.clear();
          report?.call(ImportProgress(ImportStage.epg, done: count));
        }
      }
      if (buffer.isNotEmpty) {
        await db.batch((b) => b.insertAll(db.epgPrograms, buffer));
      }
    } catch (e) {
      debugPrint('EPG import failed: $e');
    }
  }

  // ---- helpers ------------------------------------------------------------

  Future<void> _insertCategories(String playlistId, ContentKind kind, List<XtreamCategory> cats) =>
      db.batch((b) => b.insertAll(db.categories, [
            for (final (i, c) in cats.indexed)
              CategoriesCompanion.insert(playlistId: playlistId, externalId: c.id, kind: kind, name: c.name, position: Value(i)),
          ]));

  Future<void> _batched<T>(List<T> items, Future<void> Function(List<T> chunk, int offset) run) async {
    for (var i = 0; i < items.length; i += _batchSize) {
      final end = (i + _batchSize).clamp(0, items.length);
      await run(items.sublist(i, end), i);
    }
  }

  Future<String> _readSource(String url) async {
    if (url.startsWith('file://') || url.startsWith('/')) {
      return File(url.startsWith('file://') ? Uri.parse(url).toFilePath() : url).readAsString();
    }
    final res = await _dio.get<String>(url, options: Options(responseType: ResponseType.plain));
    return res.data ?? '';
  }

  static String _idForUrl(String url) {
    // Stable id per URL so favorites/history survive re-imports.
    return url.hashCode.toUnsigned(32).toRadixString(16);
  }

  static String _encodeAccount(XtreamAccount a) {
    final map = {
      'status': a.status,
      'exp_date': a.expiresAt?.toIso8601String(),
      'is_trial': a.isTrial,
      'active_cons': a.activeConnections,
      'max_connections': a.maxConnections,
    };
    return map.entries.map((e) => '${e.key}=${e.value}').join(';');
  }
}

/// Decodes the `accountInfo` column written by [PlaylistImporter].
Map<String, String> decodeAccountInfo(String? raw) {
  if (raw == null || raw.isEmpty) return const {};
  return {
    for (final part in raw.split(';'))
      if (part.contains('=')) part.substring(0, part.indexOf('=')): part.substring(part.indexOf('=') + 1),
  };
}
