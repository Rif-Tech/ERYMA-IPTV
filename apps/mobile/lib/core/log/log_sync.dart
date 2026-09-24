import 'package:dio/dio.dart';

import '../../app/config.dart';
import '../api/portal_api.dart' show InstallAuth;

/// One buffered diagnostic log entry, matching `device-logs`' expected item shape.
class LogEntry {
  const LogEntry({required this.level, required this.category, required this.message, this.context, required this.clientId, required this.createdAt});
  final String level;
  final String category;
  final String message;
  final Map<String, dynamic>? context;
  final String clientId;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'level': level,
        'category': category,
        'message': message,
        if (context != null) 'context': context,
        'client_id': clientId,
        'created_at': createdAt.toUtc().toIso8601String(),
      };
}

/// Sends buffered [LogEntry] batches to `device-logs`. A separate [Dio] instance from
/// [PortalApi]'s: API calls need a fast timeout so the UI does not hang, but a log flush is a
/// best-effort background upload that can afford to wait a little longer instead of dropping a
/// batch on a slow connection.
class LogSync {
  LogSync({Dio? dio, InstallAuth? Function()? auth})
      : _auth = auth ?? (() => null),
        _dio = dio ??
            Dio(BaseOptions(
              baseUrl: AppConfig.apiBaseUrl,
              connectTimeout: const Duration(seconds: 8),
              receiveTimeout: const Duration(seconds: 15),
              headers: {
                'Content-Type': 'application/json',
                if (AppConfig.apiAnonKey.isNotEmpty) 'apikey': AppConfig.apiAnonKey,
                if (AppConfig.apiAnonKey.isNotEmpty) 'Authorization': 'Bearer ${AppConfig.apiAnonKey}',
              },
            ));

  final Dio _dio;
  final InstallAuth? Function() _auth;

  /// Returns true on success; the caller keeps the batch (for the next flush) on any failure,
  /// including "not paired yet" (no install auth available).
  Future<bool> push(List<LogEntry> entries) async {
    if (entries.isEmpty) return true;
    final auth = _auth();
    if (auth == null) return false;
    try {
      await _dio.post<dynamic>(
        '/device-logs',
        data: {'items': entries.map((e) => e.toJson()).toList()},
        options: Options(headers: {'x-device-id': auth.uuid, if (auth.secret != null) 'x-device-secret': auth.secret!}),
      );
      return true;
    } on DioException {
      return false;
    }
  }
}
