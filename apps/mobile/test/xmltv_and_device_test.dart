import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:multiptv/core/device/device_identity.dart';
import 'package:multiptv/core/epg/xmltv_parser.dart';

void main() {
  const xml = '''<?xml version="1.0" encoding="UTF-8"?>
<tv generator-info-name="test">
  <channel id="tf1.fr"><display-name>TF1</display-name><icon src="http://logo/tf1.png"/></channel>
  <programme start="20240131200000 +0100" stop="20240131210000 +0100" channel="tf1.fr">
    <title lang="fr">Journal</title>
    <desc>Les nouvelles, &amp; plus</desc>
  </programme>
  <programme start="20240131210000 +0100" stop="20240131223000 +0100" channel="tf1.fr">
    <title><![CDATA[Film du soir]]></title>
  </programme>
  <programme start="bad" stop="20240131223000 +0100" channel="x"><title>skip</title></programme>
</tv>''';

  test('parses xmltv dates with offsets', () {
    final d = parseXmltvDate('20240131200000 +0100')!.toUtc();
    expect(d, DateTime.utc(2024, 1, 31, 19, 0));
    expect(parseXmltvDate('20240131')!.toUtc(), DateTime.utc(2024, 1, 31));
    expect(parseXmltvDate('nope'), isNull);
  });

  test('streams programmes and channels', () async {
    final channels = <XmltvChannel>[];
    final parser = XmltvParser(onChannel: channels.add);
    final programmes = await parser.parse(Stream.value(utf8.encode(xml))).toList();

    expect(channels, hasLength(1));
    expect(channels.first.displayName, 'TF1');
    expect(channels.first.icon, 'http://logo/tf1.png');

    expect(programmes, hasLength(2));
    expect(programmes[0].title, 'Journal');
    expect(programmes[0].description, 'Les nouvelles, & plus');
    expect(programmes[0].end.difference(programmes[0].start), const Duration(hours: 1));
    expect(programmes[1].title, 'Film du soir');
    expect(programmes[1].description, isNull);
  });

  test('handles gzip input transparently', () async {
    final gz = gzip.encode(utf8.encode(xml));
    final chunks = [gz.sublist(0, 10), gz.sublist(10)];
    final programmes = await XmltvParser().parse(Stream.fromIterable(chunks)).toList();
    expect(programmes, hasLength(2));
  });

  group('device identity', () {
    test('install uuid is a v4 UUID and secrets hash deterministically', () {
      final uuid = generateUuidV4();
      expect(uuid, matches(RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$')));
      expect(generateUuidV4(), isNot(uuid));
      final secret = generateInstallSecret();
      expect(secret.length, greaterThanOrEqualTo(40));
      expect(secret, isNot(contains('=')));
      // Only the hash travels to the server; it must match what Deno's SHA-256 hex would produce.
      expect(sha256Hex('abc'), 'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad');
    });

    test('mac format is locally administered unicast', () {
      final mac = macFromSeed('android:abc');
      expect(mac, matches(RegExp(r'^([0-9A-F]{2}:){5}[0-9A-F]{2}$')));
      final first = int.parse(mac.substring(0, 2), radix: 16);
      expect(first & 0x02, 0x02);
      expect(first & 0x01, 0);
      expect(macFromSeed('android:abc'), mac);
      expect(macFromSeed('android:abd'), isNot(mac));
    });

    test('device key is 6 unambiguous chars', () {
      final key = generateDeviceKey();
      expect(key, hasLength(6));
      expect(key, matches(RegExp(r'^[A-HJ-NP-Z2-9]{6}$')));
    });
  });
}
