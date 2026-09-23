import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:multiptv/core/net/dns_message.dart';

void main() {
  test('encodeQuery builds a well-formed A query', () {
    final bytes = DnsMessage.encodeQuery('example.com', type: 1);
    // QDCOUNT = 1, ANCOUNT/NSCOUNT/ARCOUNT = 0.
    expect(bytes[4], 0);
    expect(bytes[5], 1);
    expect(bytes.sublist(6, 12), everyElement(0));
    // Question name labels: 7"example" 3"com" 0.
    expect(bytes[12], 7);
    expect(String.fromCharCodes(bytes, 13, 20), 'example');
    expect(bytes[20], 3);
    expect(String.fromCharCodes(bytes, 21, 24), 'com');
    expect(bytes[24], 0);
    // QTYPE = 1 (A), QCLASS = 1 (IN).
    expect(bytes.sublist(25, 27), [0, 1]);
    expect(bytes.sublist(27, 29), [0, 1]);
  });

  test('decodeResponse follows a name-compression pointer to the A record', () {
    final packet = Uint8List.fromList([
      0x12, 0x34, // id
      0x81, 0x80, // flags
      0x00, 0x01, // qdcount
      0x00, 0x01, // ancount
      0x00, 0x00, // nscount
      0x00, 0x00, // arcount
      // question: 7"example" 3"com" 0
      7, ...'example'.codeUnits,
      3, ...'com'.codeUnits,
      0,
      0x00, 0x01, // qtype A
      0x00, 0x01, // qclass IN
      // answer: pointer to offset 12 (question name)
      0xC0, 0x0C,
      0x00, 0x01, // type A
      0x00, 0x01, // class IN
      0x00, 0x00, 0x01, 0x2C, // ttl 300
      0x00, 0x04, // rdlength
      93, 184, 216, 34,
    ]);

    final msg = DnsMessage.decodeResponse(packet);
    expect(msg.id, 0x1234);
    expect(msg.answers, hasLength(1));
    expect(msg.answers.single, InternetAddress('93.184.216.34'));
  });

  test('decodeResponse parses an AAAA record', () {
    final address = InternetAddress('2606:4700:4700::1111');
    final packet = Uint8List.fromList([
      0x00, 0x01,
      0x81, 0x80,
      0x00, 0x01,
      0x00, 0x01,
      0x00, 0x00,
      0x00, 0x00,
      1, ...'a'.codeUnits,
      0,
      0x00, 0x1C, // qtype AAAA
      0x00, 0x01,
      0xC0, 0x0C,
      0x00, 0x1C, // type AAAA
      0x00, 0x01,
      0x00, 0x00, 0x01, 0x2C,
      0x00, 0x10, // rdlength 16
      ...address.rawAddress,
    ]);

    final msg = DnsMessage.decodeResponse(packet);
    expect(msg.answers.single, address);
  });
}
