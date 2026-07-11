// lib/features/production/shared/models/production_formula_model.dart

/// Satu baris formula input: satu jenis material yang diterima dalam satu kategori.
class ProductionFormulaItem {
  final int inputId;
  final String inputNama;
  final String kategoriNama;
  final String prefixLabel;

  const ProductionFormulaItem({
    required this.inputId,
    required this.inputNama,
    required this.kategoriNama,
    required this.prefixLabel,
  });
}

/// Kumpulan formula items untuk satu output jenis.
class ProductionFormulaOutput {
  final int idJenis;
  final String namaJenis;
  final List<ProductionFormulaItem> formulas;

  const ProductionFormulaOutput({
    required this.idJenis,
    required this.namaJenis,
    required this.formulas,
  });
}
