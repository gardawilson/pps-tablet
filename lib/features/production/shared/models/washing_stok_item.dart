import '../../../../core/utils/model_helpers.dart';
import 'stok_item_data.dart';

class WashingStokItem implements StokItemData {
  final int idWashing;
  @override
  final String nama;
  @override
  final int sakSisa;
  @override
  final double beratSisa;

  /// Tanggal item tertua (paling lama mengendap) dalam stok ini — null bila
  /// stok kosong.
  final DateTime? dateCreateTertua;

  const WashingStokItem({
    required this.idWashing,
    required this.nama,
    required this.sakSisa,
    required this.beratSisa,
    this.dateCreateTertua,
  });

  factory WashingStokItem.fromJson(Map<String, dynamic> j) => WashingStokItem(
    idWashing: pickI(j, ['IdWashing', 'idWashing']) ?? 0,
    nama: pickS(j, ['Nama', 'nama']) ?? '',
    sakSisa: pickI(j, ['SakSisa', 'sakSisa']) ?? 0,
    beratSisa: pickD(j, ['BeratSisa', 'beratSisa']) ?? 0,
    dateCreateTertua: pickDT(j, ['DateCreateTertua', 'dateCreateTertua']),
  );
}
