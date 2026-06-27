// lib/features/production/washing/model/washing_formula_model.dart

class WashingFormulaItem {
  final int idFormula;
  final String kategoriKode;
  final String kategoriNama;
  final String prefixLabel;
  final int inputId;
  final String inputNama;

  const WashingFormulaItem({
    required this.idFormula,
    required this.kategoriKode,
    required this.kategoriNama,
    required this.prefixLabel,
    required this.inputId,
    required this.inputNama,
  });
}

class WashingFormulaOutput {
  final int idJenis;
  final String namaJenis;
  final List<WashingFormulaItem> formulas;

  const WashingFormulaOutput({
    required this.idJenis,
    required this.namaJenis,
    required this.formulas,
  });
}

class WashingFormulaResult {
  final Set<String> kodes;
  final List<WashingFormulaOutput> outputs;

  const WashingFormulaResult({required this.kodes, required this.outputs});
}
