// lib/features/verifikasi/repository/verifikasi_adapter.dart

import '../model/verifikasi_models.dart';
import '../model/verifikasi_operator_summary_model.dart';

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

  /// True kalau jenis produksi ini punya tahap verifikasi Production
  /// Controller — independen dari verifikasi Stock Controller (bisa diisi
  /// kapan pun, tidak perlu menunggu urutan). Jenis yang tidak punya tahap
  /// ini (mis. broker) selesai begitu Stock Controller verify.
  bool get hasOperatorVerification => false;

  /// True kalau jenis produksi ini punya tahap verifikasi Kadept (Kepala
  /// Department) — baru bisa dilakukan setelah Stock Controller & Production
  /// Controller sama-sama tuntas.
  bool get hasDepartmentVerification => false;

  /// Ambil semua NoProduksi jenis ini yang sudah selesai (complete) tapi
  /// belum tuntas seluruh tahap verifikasinya (Stock Controller, Production
  /// Controller kalau [hasOperatorVerification] true, dan Kadept kalau
  /// [hasDepartmentVerification] true).
  Future<List<VerifikasiItem>> fetchPending();

  /// Ambil ringkasan cross-check input vs output untuk satu NoProduksi.
  Future<ProductionCrossCheckSummary> fetchCrossCheck(String noProduksi);

  /// Tandai NoProduksi ini sudah diverifikasi Stock Controller.
  Future<void> verify(String noProduksi, {String? note});

  /// Batalkan verifikasi Stock Controller (mis. salah klik / mau koreksi).
  Future<void> unverify(String noProduksi, {String? note});

  /// Ambil header verifikasi (penugasan, kehadiran, status SC/PC/Kadept)
  /// untuk dialog Production Controller & Kadept. Hanya dipanggil kalau
  /// [hasOperatorVerification] atau [hasDepartmentVerification] true —
  /// jenis produksi lain boleh biarkan default (throw) di bawah ini.
  Future<VerifikasiOperatorHeader> fetchOperatorHeader(String noProduksi) =>
      throw UnimplementedError(
        '$runtimeType tidak men-support verifikasi Production Controller/Kadept',
      );

  /// Tandai NoProduksi ini sudah diverifikasi Production Controller. Hanya
  /// dipanggil kalau [hasOperatorVerification] true.
  Future<void> verifyOperator(String noProduksi, {String? note}) =>
      throw UnimplementedError(
        '$runtimeType tidak men-support verifikasi Production Controller',
      );

  /// Tandai NoProduksi ini sudah diverifikasi Kadept. Hanya dipanggil kalau
  /// [hasDepartmentVerification] true.
  Future<void> verifyDepartment(String noProduksi, {String? note}) =>
      throw UnimplementedError(
        '$runtimeType tidak men-support verifikasi Kadept',
      );
}
