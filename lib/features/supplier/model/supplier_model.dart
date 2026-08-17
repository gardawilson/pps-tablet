// lib/features/supplier/model/supplier_model.dart
class MstSupplier {
  final int idSupplier;
  final String namaSupplier;

  const MstSupplier({required this.idSupplier, required this.namaSupplier});

  factory MstSupplier.fromJson(Map<String, dynamic> j) {
    int toInt(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? 0;
    }

    return MstSupplier(
      idSupplier: toInt(j['IdSupplier']),
      namaSupplier: (j['NamaSupplier'] ?? j['NmSupplier'] ?? '').toString(),
    );
  }

  @override
  String toString() => 'MstSupplier($idSupplier, $namaSupplier)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MstSupplier &&
          runtimeType == other.runtimeType &&
          idSupplier == other.idSupplier;

  @override
  int get hashCode => idSupplier.hashCode;
}
