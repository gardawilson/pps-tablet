import '../../../../core/utils/model_helpers.dart';
import 'stok_item_data.dart';

class CrusherStokItem implements StokItemData {
  final int idCrusher;
  @override
  final String nama;
  @override
  final double beratSisa;

  /// Tanggal item tertua (paling lama mengendap) dalam stok ini — null bila
  /// stok kosong.
  final DateTime? dateCreateTertua;

  const CrusherStokItem({
    required this.idCrusher,
    required this.nama,
    required this.beratSisa,
    this.dateCreateTertua,
  });

  /// Stok crusher tidak dihitung per sak, hanya berat.
  @override
  int get sakSisa => 0;

  factory CrusherStokItem.fromJson(Map<String, dynamic> j) => CrusherStokItem(
    idCrusher: pickI(j, ['IdCrusher', 'idCrusher']) ?? 0,
    nama: pickS(j, ['NamaCrusher', 'namaCrusher', 'Nama', 'nama']) ?? '',
    beratSisa: pickD(j, ['BeratSisa', 'beratSisa']) ?? 0,
    dateCreateTertua: pickDT(j, ['DateCreateTertua', 'dateCreateTertua']),
  );
}
