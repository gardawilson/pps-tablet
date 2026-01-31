// lib/features/production/packing/model/packing_production_inputs_model.dart

import '../../shared/models/furniture_wip_item.dart';
import '../../shared/models/cabinet_material_item.dart';
import '../../../../core/utils/model_helpers.dart';

// ✅ Export item models agar bisa diakses lewat satu import
export '../../shared/models/furniture_wip_item.dart';
export '../../shared/models/cabinet_material_item.dart';

/* ===================== ROOT AGGREGATOR ===================== */

class PackingProductionInputs {
  final List<FurnitureWipItem> furnitureWip;
  final List<CabinetMaterialItem> cabinetMaterial;

  final Map<String, int> summary;

  PackingProductionInputs({
    required this.furnitureWip,
    required this.cabinetMaterial,
    required this.summary,
  });

  factory PackingProductionInputs.fromJson(Map<String, dynamic> j) {
    List<T> _listOf<T>(dynamic v, T Function(Map<String, dynamic>) f) {
      final list = (v ?? []) as List;
      return list
          .map<T>((e) => f(Map<String, dynamic>.from(e as Map)))
          .toList();
    }

    Map<String, int> _toSummary(dynamic v) {
      final m = Map<String, dynamic>.from((v ?? {}) as Map);
      return m.map((k, v) => MapEntry(k, asInt(v) ?? 0));
    }

    return PackingProductionInputs(
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

  // =====================
  // Quick totals - Furniture WIP
  // =====================

  double totalBeratFurnitureWip() =>
      furnitureWip.fold(0.0, (s, it) => s + (it.berat ?? 0));

  int totalPcsFurnitureWip() =>
      furnitureWip.fold(0, (s, it) => s + (it.pcs ?? 0));

  // =====================
  // Quick totals - Material (pakai pcs/jumlah)
  // =====================

  int totalPcsMaterial() =>
      cabinetMaterial.fold(0, (s, it) => s + (it.pcs ?? 0));

  // Total berat semua input (material tidak punya berat)
  double totalBerat() => totalBeratFurnitureWip();

  // Total items count
  int totalItems() => furnitureWip.length + cabinetMaterial.length;

  // Empty check
  bool get isEmpty => furnitureWip.isEmpty && cabinetMaterial.isEmpty;
  bool get isNotEmpty => !isEmpty;

  // CopyWith untuk state management
  PackingProductionInputs copyWith({
    List<FurnitureWipItem>? furnitureWip,
    List<CabinetMaterialItem>? cabinetMaterial,
    Map<String, int>? summary,
  }) {
    return PackingProductionInputs(
      furnitureWip: furnitureWip ?? this.furnitureWip,
      cabinetMaterial: cabinetMaterial ?? this.cabinetMaterial,
      summary: summary ?? this.summary,
    );
  }

  // Empty factory
  factory PackingProductionInputs.empty() {
    return PackingProductionInputs(
      furnitureWip: const [],
      cabinetMaterial: const [],
      summary: const {},
    );
  }

  // Summary by category
  int countFurnitureWip() => summary['furnitureWip'] ?? furnitureWip.length;

  int countCabinetMaterial() =>
      summary['cabinetMaterial'] ?? cabinetMaterial.length;

  // Group furniture WIP by partial status (reuse flags dari FurnitureWipItem)
  List<FurnitureWipItem> get fullFurnitureWip =>
      furnitureWip.where((it) => !it.isPartialRow).toList();

  List<FurnitureWipItem> get partialFurnitureWip =>
      furnitureWip.where((it) => it.isPartialRow).toList();
}
