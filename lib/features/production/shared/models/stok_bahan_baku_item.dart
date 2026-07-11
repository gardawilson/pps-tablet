import '../../../../core/utils/model_helpers.dart';
import 'stok_item_data.dart';

class StokBahanBakuItem implements StokItemData {
  final int idBB;
  @override
  final String nama;
  @override
  final int sakSisa;
  @override
  final double beratSisa;

  /// Tanggal item tertua (paling lama mengendap) dalam stok ini — null bila
  /// stok kosong.
  final DateTime? dateCreateTertua;

  const StokBahanBakuItem({
    required this.idBB,
    required this.nama,
    required this.sakSisa,
    required this.beratSisa,
    this.dateCreateTertua,
  });

  factory StokBahanBakuItem.fromJson(Map<String, dynamic> j) => StokBahanBakuItem(
    idBB: pickI(j, ['IdBB', 'idBB', 'id_bb']) ?? 0,
    nama: pickS(j, ['Nama', 'nama']) ?? '',
    sakSisa: pickI(j, ['SakSisa', 'sakSisa', 'sak_sisa']) ?? 0,
    beratSisa: pickD(j, ['BeratSisa', 'beratSisa', 'berat_sisa']) ?? 0,
    dateCreateTertua: pickDT(j, [
      'DateCreateTertua',
      'dateCreateTertua',
      'date_create_tertua',
    ]),
  );
}
