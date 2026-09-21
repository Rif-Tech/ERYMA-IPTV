import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

String formatDuration(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return h > 0 ? '$h:$m:$s' : '$m:$s';
}

String formatTime(BuildContext context, DateTime t, {required bool use24h}) {
  final locale = Localizations.localeOf(context).toString();
  return (use24h ? DateFormat.Hm(locale) : DateFormat.jm(locale)).format(t);
}

String formatDate(BuildContext context, DateTime t) {
  final locale = Localizations.localeOf(context).toString();
  return DateFormat.yMMMd(locale).format(t);
}

String formatDateTime(BuildContext context, DateTime t, {required bool use24h}) =>
    '${formatDate(context, t)} ${formatTime(context, t, use24h: use24h)}';
