import 'dart:io';
import 'dart:typed_data';

/// Minimal RFC 1035 message codec: encodes A/AAAA queries and decodes the matching answers.
/// Just enough to talk to a resolver over UDP or DNS-over-HTTPS (RFC 8484 wire format).
class DnsMessage {
  const DnsMessage({required this.id, required this.question, required this.answers});

  final int id;
  final String question;
  final List<InternetAddress> answers;

  static int _nextId = 0;

  /// Builds a query packet for [type] (1 = A, 28 = AAAA) on [host].
  static Uint8List encodeQuery(String host, {required int type}) {
    final id = (_nextId = (_nextId + 1) & 0xFFFF);
    final out = BytesBuilder();
    void u16(int v) => out.add([(v >> 8) & 0xFF, v & 0xFF]);
    u16(id);
    u16(0x0100); // standard query, recursion desired
    u16(1); // qdcount
    u16(0); // ancount
    u16(0); // nscount
    u16(0); // arcount
    for (final label in host.split('.')) {
      final bytes = label.codeUnits;
      out.addByte(bytes.length);
      out.add(bytes);
    }
    out.addByte(0); // root
    u16(type);
    u16(1); // IN class
    return out.toBytes();
  }

  /// Parses a response packet, following name-compression pointers, and returns A/AAAA answers.
  static DnsMessage decodeResponse(Uint8List data) {
    var offset = 0;
    int u16() {
      final v = (data[offset] << 8) | data[offset + 1];
      offset += 2;
      return v;
    }

    final id = u16();
    offset += 2; // flags
    final qdcount = u16();
    final ancount = u16();
    offset += 4; // nscount + arcount

    String readName() {
      final labels = <String>[];
      var jumped = false;
      var pos = offset;
      while (true) {
        final len = data[pos];
        if (len == 0) {
          pos += 1;
          break;
        }
        if ((len & 0xC0) == 0xC0) {
          if (!jumped) offset = pos + 2;
          pos = ((len & 0x3F) << 8) | data[pos + 1];
          jumped = true;
          continue;
        }
        labels.add(String.fromCharCodes(data, pos + 1, pos + 1 + len));
        pos += 1 + len;
      }
      if (!jumped) offset = pos;
      return labels.join('.');
    }

    for (var i = 0; i < qdcount; i++) {
      readName();
      offset += 4; // qtype + qclass
    }

    final answers = <InternetAddress>[];
    for (var i = 0; i < ancount; i++) {
      readName();
      final type = u16();
      offset += 2; // class
      offset += 4; // ttl
      final rdlength = u16();
      if (type == 1 && rdlength == 4) {
        answers.add(InternetAddress.fromRawAddress(data.sublist(offset, offset + 4)));
      } else if (type == 28 && rdlength == 16) {
        answers.add(InternetAddress.fromRawAddress(data.sublist(offset, offset + 16), type: InternetAddressType.IPv6));
      }
      offset += rdlength;
    }
    return DnsMessage(id: id, question: '', answers: answers);
  }
}
