// lib/features/verifikasi/repository/adapters/production_grouping.dart
//
// Helper untuk membangun [ProductionCategoryGroup] (kategori → jenis →
// label) dari dua bentuk sumber data yang berbeda:
//
//   * buildCategoryGroupFromSakRows — sumber berupa daftar item level-sak
//     (mis. BbItem, WashingItem — satu baris = satu sak), dikelompokkan
//     dulu per label lalu per jenis.
//   * buildCategoryGroupFromLabelRows — sumber sudah level-label (mis.
//     WashingOutput, atau WashingInputV2Label dari endpoint v2), tinggal
//     dikelompokkan per jenis.

import '../../model/verifikasi_models.dart';

ProductionCategoryGroup buildCategoryGroupFromSakRows<T>({
  required String categoryLabel,
  required List<T> items,
  required String? Function(T item) namaJenisOf,
  required String Function(T item) labelNoOf,
  required double Function(T item) beratOf,
}) {
  // namaJenis -> labelNo -> baris sak
  final byJenis = <String, Map<String, List<T>>>{};
  for (final item in items) {
    final rawJenis = namaJenisOf(item)?.trim();
    final jenis = (rawJenis == null || rawJenis.isEmpty) ? '-' : rawJenis;
    final label = labelNoOf(item);
    byJenis.putIfAbsent(jenis, () => {}).putIfAbsent(label, () => []).add(item);
  }

  final jenisGroups = byJenis.entries.map((jenisEntry) {
    final labels = jenisEntry.value.entries.map((labelEntry) {
      final rows = labelEntry.value;
      return ProductionLabelDetail(
        labelNo: labelEntry.key,
        sakCount: rows.length,
        berat: rows.fold(0.0, (s, r) => s + beratOf(r)),
      );
    }).toList();
    return ProductionJenisGroup(namaJenis: jenisEntry.key, labels: labels);
  }).toList();

  return ProductionCategoryGroup(
    categoryLabel: categoryLabel,
    jenisGroups: jenisGroups,
  );
}

ProductionCategoryGroup buildCategoryGroupFromLabelRows<T>({
  required String categoryLabel,
  required List<T> items,
  required String? Function(T item) namaJenisOf,
  required String Function(T item) labelNoOf,
  required int Function(T item) sakCountOf,
  required double Function(T item) beratOf,
}) {
  final byJenis = <String, List<T>>{};
  for (final item in items) {
    final rawJenis = namaJenisOf(item)?.trim();
    final jenis = (rawJenis == null || rawJenis.isEmpty) ? '-' : rawJenis;
    byJenis.putIfAbsent(jenis, () => []).add(item);
  }

  final jenisGroups = byJenis.entries.map((jenisEntry) {
    final labels = jenisEntry.value
        .map((item) => ProductionLabelDetail(
              labelNo: labelNoOf(item),
              sakCount: sakCountOf(item),
              berat: beratOf(item),
            ))
        .toList();
    return ProductionJenisGroup(namaJenis: jenisEntry.key, labels: labels);
  }).toList();

  return ProductionCategoryGroup(
    categoryLabel: categoryLabel,
    jenisGroups: jenisGroups,
  );
}
