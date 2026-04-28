class MstBarangJadi {
  final int idJenis;
  final String namaJenis;

  const MstBarangJadi({required this.idJenis, required this.namaJenis});

  factory MstBarangJadi.fromJson(Map<String, dynamic> json) {
    final id = json['idJenis'] is int
        ? json['idJenis'] as int
        : int.tryParse(json['idJenis']?.toString() ?? '0') ?? 0;
    return MstBarangJadi(
      idJenis: id,
      namaJenis: json['namaJenis']?.toString() ?? '',
    );
  }

  String get displayName => namaJenis;
}
