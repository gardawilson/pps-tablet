import 'package:flutter/foundation.dart';

import '../../../core/network/api_error.dart';
import '../model/penjualan_header_model.dart';
import '../model/penjualan_line_model.dart';
import '../repository/penjualan_repository.dart';

/// Info rekomendasi partial dikirim backend saat pcs label melebihi sisa
/// kebutuhan item — belum ada data yang diubah, murni informasi untuk
/// ditanyakan ke user lewat dialog konfirmasi.
class PenjualanPartialSuggestion {
  final String noLabel;
  final int availablePcs;
  final int pcsNeeded;
  final String message;

  const PenjualanPartialSuggestion({
    required this.noLabel,
    required this.availablePcs,
    required this.pcsNeeded,
    required this.message,
  });

  factory PenjualanPartialSuggestion.fromJson(Map<String, dynamic> j) {
    return PenjualanPartialSuggestion(
      noLabel: (j['noLabel'] ?? '').toString(),
      availablePcs: (j['availablePcs'] as num?)?.toInt() ?? 0,
      pcsNeeded: (j['pcsNeeded'] as num?)?.toInt() ?? 0,
      message: (j['message'] ?? '').toString(),
    );
  }
}

class PenjualanScanResult {
  final bool success;
  final PenjualanPartialSuggestion? suggestion;
  final String? error;

  const PenjualanScanResult.success()
    : success = true,
      suggestion = null,
      error = null;

  const PenjualanScanResult.needsConfirmation(this.suggestion)
    : success = false,
      error = null;

  const PenjualanScanResult.error(this.error)
    : success = false,
      suggestion = null;

  bool get needsConfirmation => suggestion != null;
}

/// Hasil eksekusi partial (setelah user konfirmasi) — kalau berhasil,
/// bawa kode label partial baru (BC./BL.) supaya UI bisa langsung
/// menawarkan cetak label tersebut.
class PenjualanConfirmPartialResult {
  final bool success;
  final String? error;
  final String? partialCode;
  final String? kodeKategori;

  const PenjualanConfirmPartialResult.success({
    required this.partialCode,
    required this.kodeKategori,
  }) : success = true,
       error = null;

  const PenjualanConfirmPartialResult.error(this.error)
    : success = false,
      partialCode = null,
      kodeKategori = null;
}

class PenjualanDetailViewModel extends ChangeNotifier {
  final String noBJJual;
  final PenjualanRepository repository;

  PenjualanDetailViewModel({
    required this.noBJJual,
    PenjualanRepository? repository,
  }) : repository = repository ?? PenjualanRepository();

  bool isLoading = false;
  String? error;

  PenjualanHeader? header;
  List<PenjualanLine> lines = [];

  bool get allLinesFulfilled =>
      lines.isNotEmpty && lines.every((l) => l.isComplete);

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final detail = await repository.fetchDetail(noBJJual);
      header = detail.header;
      lines = detail.lines;
    } catch (e) {
      error = apiErrorMessage(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Percobaan scan pertama — kalau pcs label melebihi sisa kebutuhan,
  /// backend mengembalikan rekomendasi partial (tanpa mengubah data apapun)
  /// alih-alih langsung menolak.
  Future<PenjualanScanResult> attemptScan(String noLabel) async {
    try {
      final body = await repository.scan(noBJJual, noLabel);
      if (body['needsConfirmation'] == true) {
        final data = body['data'] as Map<String, dynamic>? ?? {};
        return PenjualanScanResult.needsConfirmation(
          PenjualanPartialSuggestion.fromJson(data),
        );
      }
      await load();
      return const PenjualanScanResult.success();
    } catch (e) {
      return PenjualanScanResult.error(apiErrorMessage(e));
    }
  }

  /// Dipanggil setelah user menyetujui rekomendasi partial — benar-benar
  /// memecah label jadi partial sejumlah sisa kebutuhan dan mencatatnya.
  /// Bawa balik kode partial baru supaya UI bisa menawarkan cetak label.
  Future<PenjualanConfirmPartialResult> confirmPartialScan(
    String noLabel,
  ) async {
    try {
      final body = await repository.scan(
        noBJJual,
        noLabel,
        confirmPartial: true,
      );
      final data = body['data'] as Map<String, dynamic>? ?? {};
      await load();
      return PenjualanConfirmPartialResult.success(
        partialCode: data['partialCode']?.toString(),
        kodeKategori: data['kodeKategori']?.toString(),
      );
    } catch (e) {
      return PenjualanConfirmPartialResult.error(apiErrorMessage(e));
    }
  }
}
