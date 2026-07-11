import '../../../../core/utils/model_helpers.dart';
import 'stok_item_data.dart';

/// Satu baris label (NoFurnitureWIP) dengan sisa Pcs > 0 untuk satu
/// IdCabinetWIP — [sakSisa] dipetakan dari `Pcs`.
class FurnitureWipStokLabel implements StokLabelData {
  final String noFurnitureWip;
  @override
  final String label;
  final int pcs;
  @override
  final double beratSisa;
  @override
  final DateTime? dateCreate;

  const FurnitureWipStokLabel({
    required this.noFurnitureWip,
    required this.label,
    required this.pcs,
    required this.beratSisa,
    this.dateCreate,
  });

  @override
  int get sakSisa => pcs;

  factory FurnitureWipStokLabel.fromJson(Map<String, dynamic> j) =>
      FurnitureWipStokLabel(
        noFurnitureWip: pickS(j, ['NoFurnitureWIP', 'noFurnitureWip']) ?? '',
        label: pickS(j, ['Label', 'label']) ?? '',
        pcs: pickI(j, ['Pcs', 'pcs']) ?? 0,
        beratSisa: pickD(j, ['Berat', 'berat']) ?? 0,
        dateCreate: pickDT(j, ['DateCreate', 'dateCreate']),
      );
}
