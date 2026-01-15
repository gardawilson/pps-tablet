// lib/features/warehouse/model/warehouse_model.dart
class MstWarehouse {
  final int idWarehouse;
  final String namaWarehouse;
  final bool enable;

  const MstWarehouse({
    required this.idWarehouse,
    required this.namaWarehouse,
    required this.enable,
  });

  factory MstWarehouse.fromJson(Map<String, dynamic> j) {
    int _toInt(dynamic v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;

    bool _toBool(dynamic v) {
      if (v is bool) return v;
      if (v is num) return v != 0;
      if (v is String) {
        final s = v.trim().toLowerCase();
        return s == 'true' || s == '1' || s == 'y' || s == 'yes';
      }
      return false;
    }

    return MstWarehouse(
      idWarehouse: _toInt(j['IdWarehouse']),
      namaWarehouse: (j['NamaWarehouse'] ?? '') as String,
      enable: _toBool(j['Enable']),
    );
  }

  String get displayName =>
      enable ? namaWarehouse : '$namaWarehouse (non-aktif)';

  @override
  String toString() => 'MstWarehouse($idWarehouse, $namaWarehouse)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is MstWarehouse &&
              runtimeType == other.runtimeType &&
              idWarehouse == other.idWarehouse;

  @override
  int get hashCode => idWarehouse.hashCode;
}
