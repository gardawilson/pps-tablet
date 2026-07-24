// lib/features/verifikasi/repository/verifikasi_adapter.dart

import '../model/verifikasi_models.dart';

/// Kontrak yang harus dipenuhi setiap jenis produksi agar bisa muncul di
/// menu Verifikasi. Setiap jenis produksi (washing, broker, gilingan, dst)
/// punya repository/model sendiri-sendiri (tidak ada base class bersama),
/// sehingga adapter ini membungkus perbedaan itu di balik satu antarmuka.
abstract class VerifikasiAdapter {
  /// Key stabil untuk jenis produksi ini, mis. 'washing'. Dipakai untuk
  /// routing aksi verify/unverify kembali ke adapter yang benar.
  String get jenisKey;

  /// Label yang ditampilkan ke user, mis. 'Washing'.
  String get jenisLabel;

  /// Ambil semua NoProduksi jenis ini yang sudah selesai (complete) tapi
  /// belum diverifikasi supervisor.
  Future<List<VerifikasiItem>> fetchPending();

  /// Ambil ringkasan cross-check input vs output untuk satu NoProduksi.
  Future<ProductionCrossCheckSummary> fetchCrossCheck(String noProduksi);

  /// Tandai NoProduksi ini sudah diverifikasi supervisor.
  Future<void> verify(String noProduksi, {String? note});

  /// Batalkan verifikasi (mis. supervisor salah klik / mau koreksi).
  Future<void> unverify(String noProduksi, {String? note});
}
