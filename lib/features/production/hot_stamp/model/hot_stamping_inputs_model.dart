import '../../shared/models/furniture_wip_item.dart';
import '../../shared/models/cabinet_material_item.dart';
import '../../../../core/utils/model_helpers.dart';

// ✅ Export item models agar bisa diakses lewat satu import
export '../../shared/models/furniture_wip_item.dart';
export '../../shared/models/cabinet_material_item.dart';

/* ===================== ROOT AGGREGATOR ===================== */

class HotStampingInputs {
  final List<FurnitureWipItem> furnitureWip;
  final List<CabinetMaterialItem> cabinetMaterial;

  final Map<String, int> summary;

  HotStampingInputs({
    required this.furnitureWip,
    required this.cabinetMaterial,
    required this.summary,
  });

  factory HotStampingInputs.fromJson(Map<String, dynamic> j) {
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

    return HotStampingInputs(
      furnitureWip:
      _listOf(j['furnitureWip'], (m) => FurnitureWipItem.fromJson(m)),
      cabinetMaterial:
      _listOf(j['cabinetMaterial'], (m) => CabinetMaterialItem.fromJson(m)),
      summary: _toSummary(j['summary']),
    );
  }

  // Quick totals - Furniture WIP
  double totalBeratFurnitureWip() =>
      furnitureWip.fold(0.0, (s, it) => s + (it.berat ?? 0));

  int totalPcsFurnitureWip() =>
      furnitureWip.fold(0, (s, it) => s + (it.pcs ?? 0));

  // ✅ Quick totals - Cabinet Material (pakai pcs)
  int totalPcsMaterial() =>
      cabinetMaterial.fold(0, (s, it) => s + (it.pcs ?? 0));

  // Total berat semua input (hanya dari FurnitureWIP, material tidak punya berat)
  double totalBerat() => totalBeratFurnitureWip();

  // Total items count
  int totalItems() => furnitureWip.length + cabinetMaterial.length;

  // Check if has any inputs
  bool get isEmpty => furnitureWip.isEmpty && cabinetMaterial.isEmpty;
  bool get isNotEmpty => !isEmpty;

  // Copy with method untuk state management
  HotStampingInputs copyWith({
    List<FurnitureWipItem>? furnitureWip,
    List<CabinetMaterialItem>? cabinetMaterial,
    Map<String, int>? summary,
  }) {
    return HotStampingInputs(
      furnitureWip: furnitureWip ?? this.furnitureWip,
      cabinetMaterial: cabinetMaterial ?? this.cabinetMaterial,
      summary: summary ?? this.summary,
    );
  }

  // Empty factory
  factory HotStampingInputs.empty() {
    return HotStampingInputs(
      furnitureWip: [],
      cabinetMaterial: [],
      summary: {},
    );
  }

  // Get summary by category
  int countFurnitureWip() => summary['furnitureWip'] ?? furnitureWip.length;
  int countCabinetMaterial() =>
      summary['cabinetMaterial'] ?? cabinetMaterial.length;

  // ✅ BONUS: Group furniture WIP by partial status
  List<FurnitureWipItem> get fullFurnitureWip =>
      furnitureWip.where((it) => !it.isPartialRow).toList();

  List<FurnitureWipItem> get partialFurnitureWip =>
      furnitureWip.where((it) => it.isPartialRow).toList();
}
