// lib/features/warna/model/warna_model.dart
class MstWarna {
  final int idWarna;
  final String warna;
  final bool enable;

  const MstWarna({
    required this.idWarna,
    required this.warna,
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

  factory MstWarna.fromJson(Map<String, dynamic> j) {
    return MstWarna(
      idWarna: _toInt(j['IdWarna']),
      warna: (j['Warna'] ?? '') as String,
      enable: _toBool(j['Enable']),
    );
  }

  String get displayName => enable ? warna : '$warna (non-aktif)';

  @override
  String toString() => 'MstWarna($idWarna, $warna)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is MstWarna && runtimeType == other.runtimeType && idWarna == other.idWarna;

  @override
  int get hashCode => idWarna.hashCode;
}
