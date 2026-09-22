const _tags = {
  'fr', 'en', 'vf', 'vff', 'vfq', 'vo', 'vost', 'vostfr', 'multi', 'truefrench', 'french', 'subfrench',
  '4k', 'uhd', 'hd', 'fhd', 'sd', 'hdr', 'hevc', 'x264', 'x265', 'h264', 'h265', '1080p', '720p', '2160p', '480p',
};

const _accents = {
  'à': 'a', 'â': 'a', 'ä': 'a', 'á': 'a', 'ã': 'a', 'å': 'a',
  'ç': 'c',
  'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
  'î': 'i', 'ï': 'i', 'í': 'i', 'ì': 'i',
  'ô': 'o', 'ö': 'o', 'ó': 'o', 'ò': 'o', 'õ': 'o',
  'û': 'u', 'ü': 'u', 'ù': 'u', 'ú': 'u',
  'ÿ': 'y', 'ñ': 'n', 'œ': 'oe', 'æ': 'ae', 'ß': 'ss',
};

final _brackets = RegExp(r'[\[\]|{}]');
final _yearParen = RegExp(r'\((19|20)\d{2}\)');
final _nonAlnum = RegExp(r'[^a-z0-9]+');
final _bareYear = RegExp(r'^(19|20)\d{2}$');

/// `|FR| Mocro Maffia: Taxi (2024) VF 4K` → `mocro maffia taxi`.
///
/// Stored as `name_key` on every catalogue row so matching and search are plain SQL lookups.
String normalizeTitle(String raw) {
  var s = raw.toLowerCase();
  s = s.replaceAll(_brackets, ' ');
  s = s.replaceAll(_yearParen, ' ');
  s = s.replaceAll('&amp;', '&');
  s = s.split('').map((c) => _accents[c] ?? c).join();
  s = s.replaceAll('&', ' and ');
  s = s.replaceAll(_nonAlnum, ' ');
  final words = s.split(' ').where((w) => w.isNotEmpty && !_tags.contains(w)).toList();
  // A standalone trailing year duplicates the year field.
  if (words.length > 1 && _bareYear.hasMatch(words.last)) words.removeLast();
  return words.join(' ');
}

/// Year embedded in a provider title, e.g. `Kolbe (2025)`.
int? yearFromTitle(String raw) {
  final m = RegExp(r'\((19|20)(\d{2})\)').firstMatch(raw);
  return m == null ? null : int.parse('${m.group(1)}${m.group(2)}');
}
