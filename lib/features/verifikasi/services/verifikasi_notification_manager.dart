// lib/features/verifikasi/services/verifikasi_notification_manager.dart
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../../core/models/notification_item.dart';
import '../../../core/network/endpoints.dart';
import '../../../core/view_model/notification_center.dart';
import '../repository/verifikasi_repository.dart';

/// Satu notifikasi "produksi selesai, menunggu verifikasi" — payload event
/// socket `production_need_verification` yang di-broadcast backend setiap
/// kali completeXxxProduksi() commit sukses.
class VerifikasiPendingNotice {
  final String jenisProduksi;
  final String noProduksi;
  final DateTime? tglProduksi;
  final String? outputJenisNama;
  final String? completedBy;
  final DateTime? completedAt;

  const VerifikasiPendingNotice({
    required this.jenisProduksi,
    required this.noProduksi,
    this.tglProduksi,
    this.outputJenisNama,
    this.completedBy,
    this.completedAt,
  });

  factory VerifikasiPendingNotice.fromJson(Map<String, dynamic> j) {
    DateTime? parseDate(dynamic v) {
      final s = (v ?? '').toString().trim();
      if (s.isEmpty) return null;
      return DateTime.tryParse(s);
    }

    return VerifikasiPendingNotice(
      jenisProduksi: (j['jenisProduksi'] ?? '').toString().trim(),
      noProduksi: (j['noProduksi'] ?? '').toString().trim(),
      tglProduksi: parseDate(j['tglProduksi']),
      outputJenisNama: j['outputJenisNama']?.toString(),
      completedBy: j['completedBy']?.toString(),
      completedAt: parseDate(j['completedAt']),
    );
  }
}

/// Warna badge per jenis produksi untuk item notifikasi verifikasi —
/// disamakan dengan `jenisColor()` di `verifikasi_theme.dart` tapi
/// didefinisikan lokal di sini supaya layer service tidak bergantung ke
/// layer view.
const Map<String, Color> _kJenisColors = {
  'washing': Color(0xFF1E6FD9),
  'broker': Color(0xFF7C3AED),
  'gilingan': Color(0xFF0A7349),
  'inject': Color(0xFFB45309),
};

const Map<String, String> _kJenisLabels = {
  'washing': 'Washing',
  'broker': 'Broker',
  'gilingan': 'Gilingan',
  'inject': 'Inject',
};

Color _colorForJenis(String jenisKey) =>
    _kJenisColors[jenisKey] ?? const Color(0xFF1E6FD9);

String _labelForJenis(String jenisKey) => _kJenisLabels[jenisKey] ?? jenisKey;

/// Sumber notifikasi "produksi menunggu verifikasi" — dengar event socket
/// `production_need_verification` (server broadcast setiap kali produksi
/// di-complete) lalu daftarkan/hapus entrinya ke [NotificationCenter] yang
/// dipakai bell app shell & badge sidebar. Pola socket-nya meniru
/// `LabelPrintLockSocketManager` (koneksi sendiri, `disableAutoConnect` +
/// reconnect otomatis).
///
/// Cara kerja itungannya: SEKALI bootstrap dari
/// `VerifikasiRepository.fetchPending()` saat connect (bukan polling
/// berkala) untuk isi notifikasi awal yang akurat, lalu murni event-driven
/// lewat Socket.IO setelahnya — item baru masuk saat backend broadcast
/// produksi selesai, item hilang lewat [markVerified] saat item itu
/// diverifikasi dari tablet ini (server tidak broadcast event saat
/// verify/unverify).
class VerifikasiNotificationManager extends ChangeNotifier
    with WidgetsBindingObserver {
  final VerifikasiRepository _repo;
  final NotificationCenter _center;

  VerifikasiNotificationManager({
    required NotificationCenter notificationCenter,
    VerifikasiRepository? repository,
  })  : _center = notificationCenter,
        _repo = repository ?? VerifikasiRepository();

  static const _eventName = 'production_need_verification';
  static const _type = 'verifikasi';

  io.Socket? _socket;
  bool _isInitialized = false;
  bool _bootstrapped = false;

  bool get isConnected => _socket?.connected ?? false;

  /// Jumlah notifikasi verifikasi yang masih pending — dipakai badge
  /// sidebar menu "Verifikasi" (bell app shell sendiri baca total lintas
  /// jenis notifikasi langsung dari [NotificationCenter]).
  int get totalCount => _center.countByType(_type);

  String _idFor(String jenisKey, String noProduksi) =>
      '$_type:$jenisKey:$noProduksi';

  void connect() {
    if (_isInitialized && _socket != null) return;
    WidgetsBinding.instance.addObserver(this);

    // Fire-and-forget: isi notifikasi awal sekali saja, bukan polling berkala.
    _bootstrap();

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

    _socket!.on(_eventName, (data) {
      if (data is! Map) return;
      final notice =
          VerifikasiPendingNotice.fromJson(data.cast<String, dynamic>());
      if (notice.jenisProduksi.isEmpty || notice.noProduksi.isEmpty) return;
      _upsertNotice(notice);
    });

    _isInitialized = true;
    _socket!.connect();
  }

  Future<void> _bootstrap() async {
    if (_bootstrapped) return;
    _bootstrapped = true;
    try {
      final items = await _repo.fetchPending();
      for (final item in items) {
        // silent: true — ini produksi yang sudah nunggu dari sebelum app
        // dibuka, bukan "kejadian baru" yang perlu ditoast.
        _center.upsert(
          NotificationItem(
            id: _idFor(item.jenisKey, item.noProduksi),
            type: _type,
            title: '${item.jenisLabel} · ${item.noProduksi}',
            subtitle: 'Menunggu verifikasi',
            icon: Icons.verified_outlined,
            color: _colorForJenis(item.jenisKey),
            time: item.tglProduksi,
            route: '/verifikasi',
          ),
          silent: true,
        );
      }
    } catch (_) {
      // Bootstrap gagal (mis. belum login / server down) — notifikasi tetap
      // jalan murni dari event socket berikutnya. Boleh dicoba lagi.
      _bootstrapped = false;
    }
  }

  void _upsertNotice(VerifikasiPendingNotice notice) {
    final subtitleParts = <String>[
      if ((notice.outputJenisNama ?? '').trim().isNotEmpty)
        notice.outputJenisNama!.trim(),
      if ((notice.completedBy ?? '').trim().isNotEmpty)
        'selesai oleh ${notice.completedBy!.trim()}',
    ];

    _center.upsert(NotificationItem(
      id: _idFor(notice.jenisProduksi, notice.noProduksi),
      type: _type,
      title: '${_labelForJenis(notice.jenisProduksi)} · ${notice.noProduksi}',
      subtitle:
          subtitleParts.isEmpty ? 'Menunggu verifikasi' : subtitleParts.join(' · '),
      icon: Icons.verified_outlined,
      color: _colorForJenis(notice.jenisProduksi),
      time: notice.completedAt ?? notice.tglProduksi,
      route: '/verifikasi',
    ));
  }

  /// Panggil setelah verify sukses supaya notifikasinya langsung hilang
  /// tanpa menunggu apa pun (server tidak broadcast event saat verify).
  void markVerified(String jenisKey, String noProduksi) {
    _center.remove(_idFor(jenisKey, noProduksi));
  }

  /// Panggil setelah unverify sukses supaya notifikasinya muncul lagi.
  /// silent: true — ini aksi lokal user sendiri, bukan kejadian baru dari
  /// server yang perlu ditoast.
  void markUnverified(String jenisKey, String noProduksi) {
    _center.upsert(
      NotificationItem(
        id: _idFor(jenisKey, noProduksi),
        type: _type,
        title: '${_labelForJenis(jenisKey)} · $noProduksi',
        subtitle: 'Menunggu verifikasi',
        icon: Icons.verified_outlined,
        color: _colorForJenis(jenisKey),
        time: DateTime.now(),
        route: '/verifikasi',
      ),
      silent: true,
    );
  }

  void disconnect() {
    WidgetsBinding.instance.removeObserver(this);
    _isInitialized = false;
    _bootstrapped = false;
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
