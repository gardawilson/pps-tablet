class MstOperator {
  final int idOperator;
  final String namaOperator;
  final bool enable;

  const MstOperator({
    required this.idOperator,
    required this.namaOperator,
    required this.enable,
  });

  factory MstOperator.fromJson(Map<String, dynamic> j) {
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

    return MstOperator(
      idOperator: _toInt(j['IdOperator']),
      namaOperator: (j['NamaOperator'] ?? '') as String,
      enable: _toBool(j['Enable']),
    );
  }

  String get displayName => enable ? namaOperator : '$namaOperator (non-aktif)';

  @override
  String toString() => 'MstOperator($idOperator, $namaOperator)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is MstOperator && runtimeType == other.runtimeType && idOperator == other.idOperator;

  @override
  int get hashCode => idOperator.hashCode;
}
