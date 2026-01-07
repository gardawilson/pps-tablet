// lib/features/furniture_material/model/furniture_material_lookup_model.dart
class FurnitureMaterialLookupResult {
  final int idFurnitureMaterial;
  final String? nama;
  final String? itemCode;
  final bool enable;

  const FurnitureMaterialLookupResult({
    required this.idFurnitureMaterial,
    this.nama,
    this.itemCode,
    required this.enable,
  });

  static int _toInt(dynamic v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;

  static bool _toBool(dynamic v) {
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) {
      final s = v.trim().toLowerCase();
      return s == 'true' || s == '1' || s == 'y' || s == 'yes';
    }
    return false;
  }

  factory FurnitureMaterialLookupResult.fromJson(Map<String, dynamic> j) {
    return FurnitureMaterialLookupResult(
      idFurnitureMaterial: _toInt(j['IdFurnitureMaterial']),
      nama: j['Nama']?.toString(),
      itemCode: j['ItemCode']?.toString(),
      enable: _toBool(j['Enable']),
    );
  }

  String get displayText {
    final name = (nama ?? '').trim();
    final code = (itemCode ?? '').trim();
    if (name.isEmpty && code.isEmpty) return idFurnitureMaterial.toString();
    if (code.isEmpty) return name;
    if (name.isEmpty) return code;
    return '$name ($code)';
  }
}
