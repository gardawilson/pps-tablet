class MstRegu {
  final int idRegu;
  final int idBagian;
  final String namaRegu;
  final int? kepalaRegu;
  final String? namaKepalaRegu;

  const MstRegu({
    required this.idRegu,
    required this.idBagian,
    required this.namaRegu,
    this.kepalaRegu,
    this.namaKepalaRegu,
  });

  factory MstRegu.fromJson(Map<String, dynamic> json) {
    int _toInt(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toInt();
      return int.tryParse(value.toString()) ?? 0;
    }

    final idRegu = _toInt(json['IdRegu']);
    final idBagian = _toInt(json['IdBagian']);

    return MstRegu(
      idRegu: idRegu,
      idBagian: idBagian,
      namaRegu: (json['NamaRegu'] ?? '').toString(),
      kepalaRegu: json['KepalaRegu'] != null
          ? _toInt(json['KepalaRegu'])
          : null,
      namaKepalaRegu: json['NamaKepalaRegu']?.toString(),
    );
  }

  String get displayName {
    if (namaKepalaRegu != null && namaKepalaRegu!.isNotEmpty) {
      return '$namaRegu - $namaKepalaRegu';
    }
    return namaRegu;
  }

  @override
  String toString() => 'MstRegu($idRegu, $namaRegu)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MstRegu &&
          runtimeType == other.runtimeType &&
          idRegu == other.idRegu;

  @override
  int get hashCode => idRegu.hashCode;
}
