import '../../production/shared/models/barang_jadi_item.dart';
import '../../production/shared/models/furniture_wip_item.dart';
import '../../production/shared/models/cabinet_material_item.dart';
import '../../../core/utils/model_helpers.dart';

// ✅ Export item models agar bisa diakses lewat satu import
export '../../production/shared/models/barang_jadi_item.dart';
export '../../production/shared/models/furniture_wip_item.dart';
export '../../production/shared/models/cabinet_material_item.dart';

/* ===================== ROOT AGGREGATOR ===================== */

class BJJualInputs {
  final List<BarangJadiItem> barangJadi;
  final List<FurnitureWipItem> furnitureWip;
  final List<CabinetMaterialItem> cabinetMaterial;

  /// Summary dari backend: { barangJadi: n, furnitureWip: n, cabinetMaterial: n }
  final Map<String, int> summary;

  BJJualInputs({
    required this.barangJadi,
    required this.furnitureWip,
    required this.cabinetMaterial,
    required this.summary,
  });

  factory BJJualInputs.fromJson(Map<String, dynamic> j) {
    List<T> _listOf<T>(dynamic v, T Function(Map<String, dynamic>) f) {
      final list = (v ?? []) as List;
      return list.map<T>((e) => f(Map<String, dynamic>.from(e as Map))).toList();
    }

    Map<String, int> _toSummary(dynamic v) {
      final m = Map<String, dynamic>.from((v ?? {}) as Map);
      return m.map((k, v) => MapEntry(k, asInt(v) ?? 0));
    }

    return BJJualInputs(
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
            (m) => CabinetMaterialItem.fromJson(m),
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

  BJJualInputs copyWith({
    List<BarangJadiItem>? barangJadi,
    List<FurnitureWipItem>? furnitureWip,
    List<CabinetMaterialItem>? cabinetMaterial,
    Map<String, int>? summary,
  }) {
    return BJJualInputs(
      barangJadi: barangJadi ?? this.barangJadi,
      furnitureWip: furnitureWip ?? this.furnitureWip,
      cabinetMaterial: cabinetMaterial ?? this.cabinetMaterial,
      summary: summary ?? this.summary,
    );
  }

  factory BJJualInputs.empty() {
    return BJJualInputs(
      barangJadi: const [],
      furnitureWip: const [],
      cabinetMaterial: const [],
      summary: const {},
    );
  }
}
