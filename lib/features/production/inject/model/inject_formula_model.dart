// lib/features/production/inject/model/inject_formula_model.dart

class InjectFormulaInput {
  final int idFormula;
  final int inputKategoriId;
  final String inputKategoriKode;
  final String inputKategoriNama;
  final int inputId;
  final String? inputNama;

  const InjectFormulaInput({
    required this.idFormula,
    required this.inputKategoriId,
    required this.inputKategoriKode,
    required this.inputKategoriNama,
    required this.inputId,
    this.inputNama,
  });

  factory InjectFormulaInput.fromJson(Map<String, dynamic> j) =>
      InjectFormulaInput(
        idFormula: j['IdFormula'] as int,
        inputKategoriId: j['InputKategoriId'] as int,
        inputKategoriKode: j['InputKategoriKode'] as String,
        inputKategoriNama: j['InputKategoriNama'] as String,
        inputId: j['InputId'] as int,
        inputNama: j['InputNama']?.toString(),
      );
}

class InjectFormulaOutput {
  final int idJenis;
  final String namaJenis;
  final List<InjectFormulaInput> formulas;

  const InjectFormulaOutput({
    required this.idJenis,
    required this.namaJenis,
    required this.formulas,
  });

  factory InjectFormulaOutput.fromJson(Map<String, dynamic> j) =>
      InjectFormulaOutput(
        idJenis: j['idJenis'] as int,
        namaJenis: j['namaJenis'] as String,
        formulas: (j['formulas'] as List<dynamic>? ?? [])
            .map((e) => InjectFormulaInput.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class InjectFormulaData {
  final String noProduksi;
  final String? outputCategory;
  final int? outputCategoryId;
  final List<InjectFormulaOutput> outputs;

  const InjectFormulaData({
    required this.noProduksi,
    this.outputCategory,
    this.outputCategoryId,
    required this.outputs,
  });

  factory InjectFormulaData.fromJson(Map<String, dynamic> j) =>
      InjectFormulaData(
        noProduksi: j['noProduksi'] as String,
        outputCategory: j['outputCategory']?.toString(),
        outputCategoryId: j['outputCategoryId'] as int?,
        outputs: (j['outputs'] as List<dynamic>? ?? [])
            .map((e) =>
                InjectFormulaOutput.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
