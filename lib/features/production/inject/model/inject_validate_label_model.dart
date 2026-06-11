// lib/features/production/inject/model/inject_validate_label_model.dart

class InjectValidateLabelOutput {
  final int idJenis;
  final String namaJenis;

  const InjectValidateLabelOutput({
    required this.idJenis,
    required this.namaJenis,
  });

  factory InjectValidateLabelOutput.fromJson(Map<String, dynamic> j) =>
      InjectValidateLabelOutput(
        idJenis: j['idJenis'] as int,
        namaJenis: j['namaJenis'] as String,
      );
}

class InjectValidateLabelResult {
  final String noProduksi;
  final String labelCode;
  final bool valid;
  final String? reason;

  /// Informasi label yang di-scan (prefix, tableName, inputId, namaJenis)
  final String? labelPrefix;
  final String? labelTableName;
  final int? labelInputId;
  final String? labelNamaJenis;

  /// Info output produksi (hanya ada jika valid == false)
  final String? outputCategory;
  final int? outputCategoryId;
  final List<InjectValidateLabelOutput> outputs;

  const InjectValidateLabelResult({
    required this.noProduksi,
    required this.labelCode,
    required this.valid,
    this.reason,
    this.labelPrefix,
    this.labelTableName,
    this.labelInputId,
    this.labelNamaJenis,
    this.outputCategory,
    this.outputCategoryId,
    this.outputs = const [],
  });

  factory InjectValidateLabelResult.fromJson(Map<String, dynamic> j) {
    final label = j['label'] as Map<String, dynamic>?;
    final output = j['output'] as Map<String, dynamic>?;

    final rawOutputs = output?['outputs'] as List<dynamic>? ?? [];

    return InjectValidateLabelResult(
      noProduksi: j['noProduksi'] as String,
      labelCode: j['labelCode'] as String,
      valid: j['valid'] as bool,
      reason: j['reason']?.toString(),
      labelPrefix: label?['prefix']?.toString(),
      labelTableName: label?['tableName']?.toString(),
      labelInputId: label?['inputId'] as int?,
      labelNamaJenis: label?['namaJenis']?.toString(),
      outputCategory: output?['category']?.toString(),
      outputCategoryId: output?['categoryId'] as int?,
      outputs: rawOutputs
          .map((e) =>
              InjectValidateLabelOutput.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
