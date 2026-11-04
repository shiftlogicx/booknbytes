import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/supabase_config.dart';

enum LogLevel { info, warn, error, analytics }

class LogEntry {
  final String id;
  final DateTime timestamp;
  final LogLevel level;
  final String category;
  final String event;
  final Map<String, dynamic>? details;
  final String? error;
  final String? stackTrace;
  final String? restaurantId;
  final String? userId;
  bool synced;

  LogEntry({
    required this.id,
    required this.timestamp,
    required this.level,
    required this.category,
    required this.event,
    this.details,
    this.error,
    this.stackTrace,
    this.restaurantId,
    this.userId,
    this.synced = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'level': level.name.toUpperCase(),
      'category': category,
      'event': event,
      'details': details,
      'error': error,
      'stack_trace': stackTrace,
      'restaurant_id': restaurantId,
      'user_id': userId,
    };
  }

  String toFormattedString() {
    final timeStr = '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}.${timestamp.millisecond.toString().padLeft(3, '0')}';
    final buf = StringBuffer('[$timeStr] [${level.name.toUpperCase()}] [$category] $event');
    if (details != null && details!.isNotEmpty) {
      buf.write(' | ${jsonEncode(details)}');
    }
    if (error != null) {
      buf.write(' | ERROR: $error');
    }
    return buf.toString();
  }
}

class AppLogger {
  static final AppLogger _instance = AppLogger._internal();
  factory AppLogger() => _instance;
  AppLogger._internal();

  static const int _maxInMemoryLogs = 250;
  static final List<LogEntry> _logs = [];
  static final ValueNotifier<int> logCountNotifier = ValueNotifier<int>(0);

  static final List<LogEntry> _syncQueue = [];
  static Timer? _flushTimer;
  static bool _isSyncing = false;

  static String? _activeRestaurantId;
  static String? _activeUserId;

  static void setActiveContext({String? restaurantId, String? userId}) {
    if (restaurantId != null) _activeRestaurantId = restaurantId;
    if (userId != null) _activeUserId = userId;
  }

  static List<LogEntry> get logs => List.unmodifiable(_logs);

  static void info(
    String category,
    String event, {
    Map<String, dynamic>? details,
    String? restaurantId,
    String? userId,
  }) {
    _log(LogLevel.info, category, event, details: details, restaurantId: restaurantId, userId: userId);
  }

  static void warn(
    String category,
    String event, {
    Map<String, dynamic>? details,
    String? restaurantId,
    String? userId,
  }) {
    _log(LogLevel.warn, category, event, details: details, restaurantId: restaurantId, userId: userId);
  }

  static void error(
    String category,
    String event, {
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? details,
    String? restaurantId,
    String? userId,
  }) {
    _log(
      LogLevel.error,
      category,
      event,
      details: details,
      error: error?.toString(),
      stackTrace: stackTrace?.toString(),
      restaurantId: restaurantId,
      userId: userId,
    );
  }

  static void analytics(
    String event, {
    Map<String, dynamic>? details,
    Map<String, dynamic>? parameters,
    String? restaurantId,
    String? userId,
  }) {
    _log(
      LogLevel.analytics,
      'ANALYTICS',
      event,
      details: details ?? parameters,
      restaurantId: restaurantId,
      userId: userId,
    );
  }

  static void _log(
    LogLevel level,
    String category,
    String event, {
    Map<String, dynamic>? details,
    String? error,
    String? stackTrace,
    String? restaurantId,
    String? userId,
  }) {
    final entry = LogEntry(
      id: '${DateTime.now().millisecondsSinceEpoch}_${_logs.length}',
      timestamp: DateTime.now(),
      level: level,
      category: category.toUpperCase(),
      event: event,
      details: details,
      error: error,
      stackTrace: stackTrace,
      restaurantId: restaurantId ?? _activeRestaurantId,
      userId: userId ?? _activeUserId,
    );

    // 1. In-Memory Ring Buffer
    _logs.insert(0, entry);
    if (_logs.length > _maxInMemoryLogs) {
      _logs.removeLast();
    }
    logCountNotifier.value = _logs.length;

    // 2. Local Console Print
    debugPrint(entry.toFormattedString());

    // 3. Queue for Supabase Cloud Sync
    _syncQueue.add(entry);

    // Errors flush immediately; normal logs batch every 3 seconds
    if (level == LogLevel.error) {
      _flushQueueToSupabase();
    } else {
      _scheduleFlush();
    }
  }

  static void _scheduleFlush() {
    _flushTimer?.cancel();
    _flushTimer = Timer(const Duration(seconds: 3), () {
      _flushQueueToSupabase();
    });
  }

  static Future<int> flushNow() async {
    return await _flushQueueToSupabase();
  }

  static Future<int> _flushQueueToSupabase() async {
    if (_isSyncing || _syncQueue.isEmpty) return 0;
    _isSyncing = true;

    final batch = List<LogEntry>.from(_syncQueue);
    _syncQueue.clear();

    int successCount = 0;
    try {
      final deviceStr = Platform.isAndroid ? 'Android' : (Platform.isIOS ? 'iOS' : Platform.operatingSystem);
      final osVer = Platform.operatingSystemVersion;

      for (final item in batch) {
        final payload = {
          'email': item.restaurantId ?? item.userId ?? 'hotel_partner_app',
          'auth_provider': item.category,
          'status': item.level.name.toUpperCase(),
          'user_agent': jsonEncode({
            'event': item.event,
            'details': item.details ?? {},
            'error': item.error,
            'stack_trace': item.stackTrace,
            'timestamp': item.timestamp.toIso8601String(),
          }),
          'ip_address': '$deviceStr $osVer',
        };

        final res = await http.post(
          Uri.parse('${SupabaseConfig.url}/rest/v1/admin_login_logs'),
          headers: {
            'apikey': SupabaseConfig.serviceRoleKey,
            'Authorization': 'Bearer ${SupabaseConfig.serviceRoleKey}',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(payload),
        );

        if (res.statusCode >= 200 && res.statusCode < 300) {
          item.synced = true;
          successCount++;
        }
      }
    } catch (e) {
      // Offline or network error: return items back to queue
      _syncQueue.addAll(batch.where((b) => !b.synced));
    } finally {
      _isSyncing = false;
    }

    return successCount;
  }

  static void clear() {
    _logs.clear();
    _syncQueue.clear();
    logCountNotifier.value = 0;
  }

  static String exportAsText() {
    final sb = StringBuffer();
    sb.writeln('=== BOOK & BITE PARTNER DIAGNOSTIC LOGS ===');
    sb.writeln('Generated at: ${DateTime.now().toIso8601String()}');
    sb.writeln('Total entries: ${_logs.length}');
    sb.writeln('OS: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}');
    sb.writeln('Restaurant: $_activeRestaurantId | User: $_activeUserId');
    sb.writeln('===========================================');
    sb.writeln();
    for (final l in _logs.reversed) {
      sb.writeln(l.toFormattedString());
      if (l.stackTrace != null) {
        sb.writeln('  Stack: ${l.stackTrace}');
      }
    }
    return sb.toString();
  }
}
