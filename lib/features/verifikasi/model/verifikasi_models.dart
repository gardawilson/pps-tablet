// lib/features/verifikasi/model/verifikasi_models.dart

/// Satu baris NoProduksi yang sudah "Selesai" tapi belum diverifikasi
/// supervisor. Digabungkan lintas jenis produksi (washing, broker, dst).
class VerifikasiItem {
  final String noProduksi;
  final String jenisKey;
  final String jenisLabel;
  final DateTime? tglProduksi;
  final String? namaMesin;
  final int? shift;
  final bool verified;
  final String? verifiedByUsername;
  final DateTime? verifiedAt;

  const VerifikasiItem({
    required this.noProduksi,
    required this.jenisKey,
    required this.jenisLabel,
    this.tglProduksi,
    this.namaMesin,
    this.shift,
    this.verified = false,
    this.verifiedByUsername,
    this.verifiedAt,
  });
}

/// Ringkasan satu jenis output (dikelompokkan per namaJenis) untuk
/// ditampilkan read-only di layar detail verifikasi.
class ProductionOutputSummary {
  final String namaJenis;
  final int totalSak;
  final double totalBerat;

  const ProductionOutputSummary({
    required this.namaJenis,
    required this.totalSak,
    required this.totalBerat,
  });
}

/// Hasil cross-check input vs output untuk satu NoProduksi, dinormalisasi
/// dari model input/output masing-masing jenis produksi (yang berbeda-beda
/// bentuknya) menjadi struktur generik untuk ditampilkan di layar detail.
class ProductionCrossCheckSummary {
  /// Nama kategori input (mis. "bb", "washing", "gilingan") -> jumlah baris.
  final Map<String, int> inputCounts;
  final double totalInputBerat;
  final List<ProductionOutputSummary> outputs;
  final double totalOutputBerat;

  const ProductionCrossCheckSummary({
    required this.inputCounts,
    required this.totalInputBerat,
    required this.outputs,
    required this.totalOutputBerat,
  });
}
