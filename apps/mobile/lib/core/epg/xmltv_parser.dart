import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:xml/xml_events.dart';

@immutable
class XmltvProgramme {
  const XmltvProgramme({
    required this.channelId,
    required this.start,
    required this.end,
    required this.title,
    this.description,
  });
  final String channelId;
  final DateTime start;
  final DateTime end;
  final String title;
  final String? description;
}

@immutable
class XmltvChannel {
  const XmltvChannel({required this.id, required this.displayName, this.icon});
  final String id;
  final String displayName;
  final String? icon;
}

/// XMLTV date: `20240131203000 +0100` (offset optional).
DateTime? parseXmltvDate(String? raw) {
  if (raw == null) return null;
  final s = raw.trim();
  final m = RegExp(r'^(\d{4})(\d{2})?(\d{2})?(\d{2})?(\d{2})?(\d{2})?\s*([+-]\d{4})?$').firstMatch(s);
  if (m == null) return null;
  int part(int i, [int def = 0]) => m.group(i) == null ? def : int.parse(m.group(i)!);
  var dt = DateTime.utc(part(1), part(2, 1), part(3, 1), part(4), part(5), part(6));
  final tz = m.group(7);
  if (tz != null) {
    final sign = tz.startsWith('-') ? -1 : 1;
    final h = int.parse(tz.substring(1, 3));
    final min = int.parse(tz.substring(3, 5));
    dt = dt.subtract(Duration(hours: sign * h, minutes: sign * min));
  }
  return dt.toLocal();
}

/// Detects gzip magic bytes and transparently decompresses.
Stream<List<int>> maybeGunzip(Stream<List<int>> bytes) async* {
  final iterator = StreamIterator(bytes);
  if (!await iterator.moveNext()) return;
  final first = iterator.current;
  final isGzip = first.length >= 2 && first[0] == 0x1f && first[1] == 0x8b;
  final rest = () async* {
    yield first;
    while (await iterator.moveNext()) {
      yield iterator.current;
    }
  }();
  yield* isGzip ? rest.transform(gzip.decoder) : rest;
}

/// Streams programmes and channels out of an XMLTV byte stream without buffering the document.
class XmltvParser {
  XmltvParser({this.onChannel});

  final void Function(XmltvChannel channel)? onChannel;

  Stream<XmltvProgramme> parse(Stream<List<int>> bytes) async* {
    final events = maybeGunzip(bytes)
        .transform(utf8.decoder)
        .toXmlEvents()
        .normalizeEvents()
        .flatten();

    String? channelId;
    String? start;
    String? stop;
    String? title;
    String? desc;
    String? chanId;
    String? chanName;
    String? chanIcon;
    final text = StringBuffer();
    var inProgramme = false;
    var inChannel = false;
    String? currentElement;

    await for (final event in events) {
      if (event is XmlStartElementEvent) {
        final name = event.localName;
        if (name == 'programme') {
          inProgramme = true;
          channelId = _attr(event, 'channel');
          start = _attr(event, 'start');
          stop = _attr(event, 'stop');
          title = null;
          desc = null;
        } else if (name == 'channel') {
          inChannel = true;
          chanId = _attr(event, 'id');
          chanName = null;
          chanIcon = null;
        } else if (inChannel && name == 'icon') {
          chanIcon = _attr(event, 'src');
        }
        currentElement = name;
        text.clear();
      } else if (event is XmlTextEvent || event is XmlCDATAEvent) {
        final value = event is XmlTextEvent ? event.value : (event as XmlCDATAEvent).value;
        if (currentElement == 'title' || currentElement == 'desc' || currentElement == 'display-name') {
          text.write(value);
        }
      } else if (event is XmlEndElementEvent) {
        final name = event.localName;
        if (inProgramme) {
          if (name == 'title' && title == null) title = text.toString().trim();
          if (name == 'desc' && desc == null) desc = text.toString().trim();
          if (name == 'programme') {
            inProgramme = false;
            final s = parseXmltvDate(start);
            final e = parseXmltvDate(stop);
            if (channelId != null && s != null && e != null && e.isAfter(s)) {
              yield XmltvProgramme(
                channelId: channelId,
                start: s,
                end: e,
                title: title ?? '',
                description: (desc == null || desc.isEmpty) ? null : desc,
              );
            }
          }
        } else if (inChannel) {
          if (name == 'display-name' && chanName == null) chanName = text.toString().trim();
          if (name == 'channel') {
            inChannel = false;
            if (chanId != null) {
              onChannel?.call(XmltvChannel(id: chanId, displayName: chanName ?? chanId, icon: chanIcon));
            }
          }
        }
        currentElement = null;
        text.clear();
      }
    }
  }

  static String? _attr(XmlStartElementEvent e, String name) {
    for (final a in e.attributes) {
      if (a.localName == name) return a.value;
    }
    return null;
  }
}
