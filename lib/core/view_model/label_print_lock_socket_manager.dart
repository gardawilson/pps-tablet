import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../network/endpoints.dart';

class LabelPrintLockInfo {
  final String noLabel;
  final String? lockedBy;
  final String? username;
  final DateTime? lockedAt;
  final DateTime? expiresAt;

  const LabelPrintLockInfo({
    required this.noLabel,
    this.lockedBy,
    this.username,
    this.lockedAt,
    this.expiresAt,
  });

  String get displayUser {
    final u = (username ?? '').trim();
    if (u.isNotEmpty) return u;
    final by = (lockedBy ?? '').trim();
    return by.isNotEmpty ? by : 'user lain';
  }

  factory LabelPrintLockInfo.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) {
      final s = (v ?? '').toString().trim();
      if (s.isEmpty) return null;
      return DateTime.tryParse(s);
    }

    return LabelPrintLockInfo(
      noLabel: (json['noLabel'] ?? '').toString().trim(),
      lockedBy: json['lockedBy']?.toString(),
      username: json['username']?.toString(),
      lockedAt: parseDate(json['lockedAt']),
      expiresAt: parseDate(json['expiresAt']),
    );
  }
}

class LabelPrintLockSocketManager extends ChangeNotifier
    with WidgetsBindingObserver {
  io.Socket? _socket;
  bool _isInitialized = false;
  final Map<String, LabelPrintLockInfo> _locks = <String, LabelPrintLockInfo>{};
  final Map<String, int> _printCounts = <String, int>{};

  bool get isConnected => _socket?.connected ?? false;
  UnmodifiableMapView<String, LabelPrintLockInfo> get locks =>
      UnmodifiableMapView(_locks);

  LabelPrintLockInfo? lockOf(String noLabel) => _locks[noLabel.trim()];
  int? printCountOf(String noLabel) => _printCounts[noLabel.trim()];

  void setPrintCount(String noLabel, int count) {
    final key = noLabel.trim();
    if (key.isEmpty) return;
    if (_printCounts[key] == count) return;
    _printCounts[key] = count;
    notifyListeners();
  }

  /// Optimistic local lock update — panggil setelah lockApi.acquire() berhasil
  /// agar badge "Printing" muncul tanpa menunggu WebSocket broadcast dari server.
  void setLocalLock(String noLabel, LabelPrintLockInfo info) {
    final key = noLabel.trim();
    if (key.isEmpty) return;
    _locks[key] = info;
    notifyListeners();
  }

  /// Hapus lock secara lokal — panggil setelah lockApi.release() selesai
  /// sebagai fallback jika server lambat broadcast lock_released.
  void clearLocalLock(String noLabel) {
    final key = noLabel.trim();
    if (_locks.remove(key) != null) notifyListeners();
  }

  void connect() {
    if (_isInitialized && _socket != null) return;
    WidgetsBinding.instance.addObserver(this);

    final fallback = ApiConstants.baseUrl.replaceFirst(RegExp(r'/api/?$'), '');
    final baseUrl = ApiConstants.socketBaseUrl.trim().isNotEmpty
        ? ApiConstants.socketBaseUrl
        : fallback;

    _socket = io.io(
      baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .enableReconnection()
          .setReconnectionAttempts(999999)
          .setReconnectionDelay(1200)
          .disableAutoConnect()
          .build(),
    );

    _socket!.onConnect((_) => notifyListeners());
    _socket!.onDisconnect((_) => notifyListeners());
    _socket!.onConnectError((_) => notifyListeners());

    _socket!.on('initial_locks', (data) {
      final next = <String, LabelPrintLockInfo>{};
      if (data is List) {
        for (final item in data) {
          if (item is! Map) continue;
          final info = LabelPrintLockInfo.fromJson(
            item.cast<String, dynamic>(),
          );
          if (info.noLabel.isNotEmpty) {
            next[info.noLabel] = info;
          }
        }
      }
      _locks
        ..clear()
        ..addAll(next);
      notifyListeners();
    });

    _socket!.on('lock_acquired', (data) {
      if (data is! Map) return;
      final info = LabelPrintLockInfo.fromJson(data.cast<String, dynamic>());
      if (info.noLabel.isEmpty) return;
      _locks[info.noLabel] = info;
      notifyListeners();
    });

    _socket!.on('lock_released', (data) {
      if (data is! Map) return;
      final noLabel = (data['noLabel'] ?? '').toString().trim();
      if (noLabel.isEmpty) return;
      final changed = _locks.remove(noLabel) != null;
      if (changed) notifyListeners();
    });

    void onPrintCount(dynamic data) {
      if (data is! Map) return;
      final noLabel = (data['noLabel'] ?? '').toString().trim();
      final countRaw = data['hasBeenPrinted'];
      final count = (countRaw is num)
          ? countRaw.toInt()
          : int.tryParse('$countRaw');
      if (noLabel.isEmpty || count == null) return;
      if (_printCounts[noLabel] == count) return;
      _printCounts[noLabel] = count;
      notifyListeners();
    }

    _socket!.on('print_count_updated', onPrintCount);
    _socket!.on('print_confirmed', onPrintCount);

    _isInitialized = true;
    _socket!.connect();
  }

  void disconnect() {
    WidgetsBinding.instance.removeObserver(this);
    _isInitialized = false;
    _locks.clear();
    _printCounts.clear();
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_socket == null || !(_socket!.connected)) {
        _socket?.connect();
      }
    }
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}
