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
  final String? hourStart;
  final String? hourEnd;
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
    this.hourStart,
    this.hourEnd,
    this.verified = false,
    this.verifiedByUsername,
    this.verifiedAt,
  });
}

/// Satu label fisik (mis. satu NoWashing / NoBahanBaku / NoBroker) di dalam
/// satu jenis material — baris paling detail pada tabel cross-check.
class ProductionLabelDetail {
  final String labelNo;
  final int sakCount;
  final double berat;

  const ProductionLabelDetail({
    required this.labelNo,
    required this.sakCount,
    required this.berat,
  });
}

/// Satu jenis material (namaJenis), berisi satu atau lebih label.
class ProductionJenisGroup {
  final String namaJenis;
  final List<ProductionLabelDetail> labels;

  const ProductionJenisGroup({
    required this.namaJenis,
    required this.labels,
  });

  int get totalSak => labels.fold(0, (s, l) => s + l.sakCount);
  double get totalBerat => labels.fold(0.0, (s, l) => s + l.berat);
}

/// Satu kategori (mis. "Bahan Baku", "Washing", "Gilingan" untuk input;
/// "Output" untuk output), berisi satu atau lebih jenis material.
class ProductionCategoryGroup {
  final String categoryLabel;
  final List<ProductionJenisGroup> jenisGroups;

  const ProductionCategoryGroup({
    required this.categoryLabel,
    required this.jenisGroups,
  });

  int get totalSak => jenisGroups.fold(0, (s, j) => s + j.totalSak);
  double get totalBerat => jenisGroups.fold(0.0, (s, j) => s + j.totalBerat);
}

/// Hasil cross-check input vs output untuk satu NoProduksi, dinormalisasi
/// dari model input/output masing-masing jenis produksi (yang berbeda-beda
/// bentuknya) menjadi struktur generik kategori → jenis → label.
class ProductionCrossCheckSummary {
  final List<ProductionCategoryGroup> inputGroups;
  final List<ProductionCategoryGroup> outputGroups;

  const ProductionCrossCheckSummary({
    required this.inputGroups,
    required this.outputGroups,
  });

  double get totalInputBerat =>
      inputGroups.fold(0.0, (s, g) => s + g.totalBerat);

  double get totalOutputBerat =>
      outputGroups.fold(0.0, (s, g) => s + g.totalBerat);

  /// Selisih berat output terhadap input (biasanya negatif — susut proses).
  double get selisihBerat => totalOutputBerat - totalInputBerat;

  /// Persentase rendemen (output / input). Null kalau input 0 (hindari NaN).
  double? get rendemenPct =>
      totalInputBerat > 0 ? (totalOutputBerat / totalInputBerat) * 100 : null;
}
