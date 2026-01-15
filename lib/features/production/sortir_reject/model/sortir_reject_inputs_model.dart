

/* ===================== ROOT AGGREGATOR ===================== */

import '../../shared/models/barang_jadi_item.dart';
import '../../shared/models/cabinet_material_item.dart';
import '../../shared/models/furniture_wip_item.dart';
import '../../shared/models/model_helpers.dart';

class SortirRejectInputs {
  final List<BarangJadiItem> barangJadi;
  final List<FurnitureWipItem> furnitureWip;
  final List<CabinetMaterialItem> cabinetMaterial;

  /// Summary dari backend: { barangJadi: n, furnitureWip: n, cabinetMaterial: n }
  final Map<String, int> summary;

  SortirRejectInputs({
    required this.barangJadi,
    required this.furnitureWip,
    required this.cabinetMaterial,
    required this.summary,
  });

  factory SortirRejectInputs.fromJson(Map<String, dynamic> j) {
    List<T> _listOf<T>(dynamic v, T Function(Map<String, dynamic>) f) {
      final list = (v ?? []) as List;
      return list.map<T>((e) => f(Map<String, dynamic>.from(e as Map))).toList();
    }

    Map<String, int> _toSummary(dynamic v) {
      final m = Map<String, dynamic>.from((v ?? {}) as Map);
      return m.map((k, v) => MapEntry(k, asInt(v) ?? 0));
    }

    // 🔧 Special: cabinetMaterial dari sortir reject kadang kirim "jumlah" (bukan pcs)
    // dan idCabinetMaterial berbentuk string.
    CabinetMaterialItem _cabinetItemFromSortir(Map<String, dynamic> m) {
      final mm = Map<String, dynamic>.from(m);

      // normalize jumlah -> Pcs supaya CabinetMaterialItem existing bisa pakai
      // (kalau CabinetMaterialItem kamu fieldnya "pcs")
      if (mm['pcs'] == null && mm['Pcs'] == null && mm['jumlah'] != null) {
        mm['pcs'] = mm['jumlah'];
      }

      // normalize key idCabinetMaterial (kadang pascal/camel)
      if (mm['IdCabinetMaterial'] == null && mm['idCabinetMaterial'] != null) {
        mm['IdCabinetMaterial'] = mm['idCabinetMaterial'];
      }

      return CabinetMaterialItem.fromJson(mm);
    }

    return SortirRejectInputs(
      barangJadi: _listOf(
        j['barangJadi'] ?? j['barangJadiItems'] ?? j['bj'],
            (m) => BarangJadiItem.fromJson(m),
      ),
      furnitureWip: _listOf(
        j['furnitureWip'],
            (m) => FurnitureWipItem.fromJson(m),
      ),
      cabinetMaterial: _listOf(
        j['cabinetMaterial'],
            (m) => _cabinetItemFromSortir(m),
      ),
      summary: _toSummary(j['summary']),
    );
  }

  /* =====================
   * Quick totals - Barang Jadi
   * ===================== */

  double totalBeratBarangJadi() =>
      barangJadi.fold(0.0, (s, it) => s + (it.berat ?? 0));

  int totalPcsBarangJadi() =>
      barangJadi.fold(0, (s, it) => s + (it.pcs ?? 0));

  List<BarangJadiItem> get fullBarangJadi =>
      barangJadi.where((it) => !it.isPartialRow).toList();

  List<BarangJadiItem> get partialBarangJadi =>
      barangJadi.where((it) => it.isPartialRow).toList();

  /* =====================
   * Quick totals - Furniture WIP
   * ===================== */

  double totalBeratFurnitureWip() =>
      furnitureWip.fold(0.0, (s, it) => s + (it.berat ?? 0));

  int totalPcsFurnitureWip() =>
      furnitureWip.fold(0, (s, it) => s + (it.pcs ?? 0));

  List<FurnitureWipItem> get fullFurnitureWip =>
      furnitureWip.where((it) => !it.isPartialRow).toList();

  List<FurnitureWipItem> get partialFurnitureWip =>
      furnitureWip.where((it) => it.isPartialRow).toList();

  /* =====================
   * Quick totals - Material
   * ===================== */

  int totalPcsMaterial() =>
      cabinetMaterial.fold(0, (s, it) => s + (it.pcs ?? 0));

  /* =====================
   * Totals overall
   * ===================== */

  double totalBerat() => totalBeratBarangJadi() + totalBeratFurnitureWip();

  int totalItems() =>
      barangJadi.length + furnitureWip.length + cabinetMaterial.length;

  bool get isEmpty =>
      barangJadi.isEmpty && furnitureWip.isEmpty && cabinetMaterial.isEmpty;

  bool get isNotEmpty => !isEmpty;

  /* =====================
   * Summary helpers
   * ===================== */

  int countBarangJadi() => summary['barangJadi'] ?? barangJadi.length;

  int countFurnitureWip() => summary['furnitureWip'] ?? furnitureWip.length;

  int countCabinetMaterial() =>
      summary['cabinetMaterial'] ?? cabinetMaterial.length;

  /* =====================
   * CopyWith
   * ===================== */

  SortirRejectInputs copyWith({
    List<BarangJadiItem>? barangJadi,
    List<FurnitureWipItem>? furnitureWip,
    List<CabinetMaterialItem>? cabinetMaterial,
    Map<String, int>? summary,
  }) {
    return SortirRejectInputs(
      barangJadi: barangJadi ?? this.barangJadi,
      furnitureWip: furnitureWip ?? this.furnitureWip,
      cabinetMaterial: cabinetMaterial ?? this.cabinetMaterial,
      summary: summary ?? this.summary,
    );
  }

  factory SortirRejectInputs.empty() {
    return SortirRejectInputs(
      barangJadi: const [],
      furnitureWip: const [],
      cabinetMaterial: const [],
      summary: const {},
    );
  }
}
