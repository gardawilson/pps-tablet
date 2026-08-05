import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../../core/network/endpoints.dart';

/// Payload realtime yang dikirim server setiap ada scan hasil baru masuk
/// untuk suatu stock opname (event `stock_opname_hasil_inserted`).
class SoV2HasilInsertedEvent {
  final String stockOpnameNo;
  final String categoryCode;
  final String labelNo;
  final int? sackCount;
  final int? pieceCount;
  final double? weight;
  final String? referenceBlok;
  final int? referenceLocationId;
  final String? scannedBlok;
  final int? scannedLocationId;
  final bool isLocationMismatch;
  final String? scannedByUsername;

  const SoV2HasilInsertedEvent({
    required this.stockOpnameNo,
    required this.categoryCode,
    required this.labelNo,
    this.sackCount,
    this.pieceCount,
    this.weight,
    this.referenceBlok,
    this.referenceLocationId,
    this.scannedBlok,
    this.scannedLocationId,
    required this.isLocationMismatch,
    this.scannedByUsername,
  });

  factory SoV2HasilInsertedEvent.fromJson(Map<String, dynamic> json) {
    int? asInt(dynamic v) => v is num ? v.toInt() : int.tryParse('$v');
    double? asDouble(dynamic v) => v is num ? v.toDouble() : double.tryParse('$v');

    return SoV2HasilInsertedEvent(
      stockOpnameNo: (json['stockOpnameNo'] ?? '').toString(),
      categoryCode: (json['categoryCode'] ?? '').toString(),
      labelNo: (json['labelNo'] ?? '').toString(),
      sackCount: json.containsKey('sackCount') ? asInt(json['sackCount']) : null,
      pieceCount: json.containsKey('pieceCount') ? asInt(json['pieceCount']) : null,
      weight: json.containsKey('weight') ? asDouble(json['weight']) : null,
      referenceBlok: json['referenceBlok']?.toString(),
      referenceLocationId: json.containsKey('referenceLocationId')
          ? asInt(json['referenceLocationId'])
          : null,
      scannedBlok: json['scannedBlok']?.toString(),
      scannedLocationId: json.containsKey('scannedLocationId')
          ? asInt(json['scannedLocationId'])
          : null,
      isLocationMismatch: json['isLocationMismatch'] == true,
      scannedByUsername: json['scannedByUsername']?.toString(),
    );
  }
}

/// Payload realtime yang dikirim server setiap hasil scan dihapus (event
/// `stock_opname_hasil_deleted`) — mis. dipakai buat perbaiki label yang
/// salah lokasi (isLocationMismatch) supaya bisa discan ulang.
class SoV2HasilDeletedEvent {
  final String stockOpnameNo;
  final String categoryCode;
  final String labelNo;
  final String? deletedByUsername;

  const SoV2HasilDeletedEvent({
    required this.stockOpnameNo,
    required this.categoryCode,
    required this.labelNo,
    this.deletedByUsername,
  });

  factory SoV2HasilDeletedEvent.fromJson(Map<String, dynamic> json) {
    return SoV2HasilDeletedEvent(
      stockOpnameNo: (json['stockOpnameNo'] ?? '').toString(),
      categoryCode: (json['categoryCode'] ?? '').toString(),
      labelNo: (json['labelNo'] ?? '').toString(),
      deletedByUsername: json['deletedByUsername']?.toString(),
    );
  }
}

/// Socket.IO client global untuk fitur Stock Opname v2 — connect sekali per
/// sesi app (didaftarkan di main.dart), lalu screen aktif join/leave room
/// sesuai `stockOpnameNo` yang sedang dibuka.
class SoV2SocketManager extends ChangeNotifier with WidgetsBindingObserver {
  io.Socket? _socket;
  bool _isInitialized = false;
  final Set<String> _joinedRooms = <String>{};
  final List<void Function(SoV2HasilInsertedEvent)> _insertedListeners = [];
  final List<void Function(SoV2HasilDeletedEvent)> _deletedListeners = [];

  bool get isConnected => _socket?.connected ?? false;

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

    _socket!.onConnect((_) {
      // Rejoin semua room aktif kalau socket sempat reconnect.
      for (final room in _joinedRooms) {
        _socket!.emit('join_stock_opname', room);
      }
      notifyListeners();
    });
    _socket!.onDisconnect((_) => notifyListeners());
    _socket!.onConnectError((_) => notifyListeners());

    _socket!.on('stock_opname_hasil_inserted', (data) {
      print('🔌 stock_opname_hasil_inserted: $data');
      if (data is! Map) return;
      final event = SoV2HasilInsertedEvent.fromJson(data.cast<String, dynamic>());
      if (event.stockOpnameNo.isEmpty) return;
      for (final listener in List.of(_insertedListeners)) {
        listener(event);
      }
    });

    _socket!.on('stock_opname_hasil_deleted', (data) {
      print('🔌 stock_opname_hasil_deleted: $data');
      if (data is! Map) return;
      final event = SoV2HasilDeletedEvent.fromJson(data.cast<String, dynamic>());
      if (event.stockOpnameNo.isEmpty) return;
      for (final listener in List.of(_deletedListeners)) {
        listener(event);
      }
    });

    _isInitialized = true;
    _socket!.connect();
  }

  void joinStockOpname(String stockOpnameNo) {
    final no = stockOpnameNo.trim();
    if (no.isEmpty || !_joinedRooms.add(no)) return;
    _socket?.emit('join_stock_opname', no);
  }

  void leaveStockOpname(String stockOpnameNo) {
    final no = stockOpnameNo.trim();
    if (no.isEmpty || !_joinedRooms.remove(no)) return;
    _socket?.emit('leave_stock_opname', no);
  }

  /// Daftarkan callback untuk event `stock_opname_hasil_inserted`. Panggil
  /// hasil (unsubscribe function) saat dispose.
  VoidCallback addHasilInsertedListener(
    void Function(SoV2HasilInsertedEvent event) listener,
  ) {
    _insertedListeners.add(listener);
    return () => _insertedListeners.remove(listener);
  }

  /// Daftarkan callback untuk event `stock_opname_hasil_deleted`. Panggil
  /// hasil (unsubscribe function) saat dispose.
  VoidCallback addHasilDeletedListener(
    void Function(SoV2HasilDeletedEvent event) listener,
  ) {
    _deletedListeners.add(listener);
    return () => _deletedListeners.remove(listener);
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
    WidgetsBinding.instance.removeObserver(this);
    _isInitialized = false;
    _joinedRooms.clear();
    _insertedListeners.clear();
    _deletedListeners.clear();
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    super.dispose();
  }
}
