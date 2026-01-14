class MstPembeli {
  final int idPembeli;
  final String namaPembeli;
  final bool enable;

  const MstPembeli({
    required this.idPembeli,
    required this.namaPembeli,
    required this.enable,
  });

  factory MstPembeli.fromJson(Map<String, dynamic> j) {
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

    return MstPembeli(
      idPembeli: _toInt(j['IdPembeli']),
      namaPembeli: (j['NamaPembeli'] ?? '') as String,
      enable: _toBool(j['Enable']),
    );
  }

  String get displayName => enable ? namaPembeli : '$namaPembeli (non-aktif)';

  @override
  String toString() => 'MstPembeli($idPembeli, $namaPembeli)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is MstPembeli &&
              runtimeType == other.runtimeType &&
              idPembeli == other.idPembeli;

  @override
  int get hashCode => idPembeli.hashCode;
}
