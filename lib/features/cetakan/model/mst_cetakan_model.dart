// lib/features/cetakan/model/mst_cetakan_model.dart
class MstCetakan {
  final int idCetakan;
  final int idBj;
  final bool enable;

  final String namaCetakan;

  final double lebar;
  final double panjang;
  final double tebal;

  final double beratCetakan;
  final double beratCavity;
  final int jumlahCavity;

  final bool hotRunner;
  final bool hydrolicCore;
  final bool electricalSwitch;
  final bool inputAngin;
  final bool inputAir;

  final double cycleTime;
  final double pcsPerJam;

  const MstCetakan({
    required this.idCetakan,
    required this.idBj,
    required this.enable,
    required this.namaCetakan,
    required this.lebar,
    required this.panjang,
    required this.tebal,
    required this.beratCetakan,
    required this.beratCavity,
    required this.jumlahCavity,
    required this.hotRunner,
    required this.hydrolicCore,
    required this.electricalSwitch,
    required this.inputAngin,
    required this.inputAir,
    required this.cycleTime,
    required this.pcsPerJam,
  });

  // -------- tolerant parsers (mirip pola operator) --------
  static int _toInt(dynamic v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    if (v is String) {
      final s = v.trim().replaceAll(',', '.');
      return double.tryParse(s) ?? 0.0;
    }
    return 0.0;
  }

  static bool _toBool(dynamic v) {
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) {
      final s = v.trim().toLowerCase();
      return s == 'true' || s == '1' || s == 'y' || s == 'yes';
    }
    return false;
  }

  factory MstCetakan.fromJson(Map<String, dynamic> j) {
    return MstCetakan(
      idCetakan: _toInt(j['IdCetakan']),
      idBj: _toInt(j['IdBJ']),
      enable: _toBool(j['Enable']),
      namaCetakan: (j['NamaCetakan'] ?? '') as String,

      lebar: _toDouble(j['Lebar']),
      panjang: _toDouble(j['Panjang']),
      tebal: _toDouble(j['Tebal']),

      beratCetakan: _toDouble(j['BeratCetakan']),
      beratCavity: _toDouble(j['BeratCavity']),
      jumlahCavity: _toInt(j['JumlahCavity']),

      hotRunner: _toBool(j['HotRunner']),
      hydrolicCore: _toBool(j['HydrolicCore']),
      electricalSwitch: _toBool(j['ElectricalSwitch']),
      inputAngin: _toBool(j['InputAngin']),
      inputAir: _toBool(j['InputAir']),

      cycleTime: _toDouble(j['CycleTime']),
      pcsPerJam: _toDouble(j['PcsPerJam']),
    );
  }

  /// label yang dipakai di dropdown
  String get displayName => enable ? namaCetakan : '$namaCetakan (non-aktif)';

  @override
  String toString() => 'MstCetakan($idCetakan, $namaCetakan)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is MstCetakan && runtimeType == other.runtimeType && idCetakan == other.idCetakan;

  @override
  int get hashCode => idCetakan.hashCode;
}
