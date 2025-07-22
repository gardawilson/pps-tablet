class LabelValidationResult {
  final bool success;
  final String message;
  final String label;
  final String labelType;
  final Map<String, dynamic> parsed;
  final String noso;
  final String username;
  final bool isValidFormat;
  final bool isValidCategory;
  final bool isValidWarehouse;
  final bool isDuplicate;
  final bool foundInStockOpname;
  final bool canInsert;
  final int? idWarehouse;
  // Detail fields - sekarang flat
  final int? jmlhSak;
  final double? berat;
  final String? idLokasi;

  LabelValidationResult({
    required this.success,
    required this.message,
    required this.label,
    required this.labelType,
    required this.parsed,
    required this.noso,
    required this.username,
    required this.isValidFormat,
    required this.isValidCategory,
    required this.isValidWarehouse,
    required this.isDuplicate,
    required this.foundInStockOpname,
    required this.canInsert,
    this.idWarehouse,
    this.jmlhSak,
    this.berat,
    this.idLokasi,
  });

  factory LabelValidationResult.fromJson(Map<String, dynamic> json) {
    return LabelValidationResult(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      label: json['label'] ?? '',
      labelType: json['labelType'] ?? '',
      parsed: Map<String, dynamic>.from(json['parsed'] ?? {}),
      noso: json['noso'] ?? '',
      username: json['username'] ?? '',
      isValidFormat: json['isValidFormat'] ?? false,
      isValidCategory: json['isValidCategory'] ?? false,
      isValidWarehouse: json['isValidWarehouse'] ?? false,
      isDuplicate: json['isDuplicate'] ?? false,
      foundInStockOpname: json['foundInStockOpname'] ?? false,
      canInsert: json['canInsert'] ?? false,
      idWarehouse: json['idWarehouse'],
      // Detail fields langsung dari root JSON
      jmlhSak: json['jmlhSak'],
      berat: json['berat'] != null ? (json['berat'] as num).toDouble() : null,
      idLokasi: json['idLokasi']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'label': label,
      'labelType': labelType,
      'parsed': parsed,
      'noso': noso,
      'username': username,
      'isValidFormat': isValidFormat,
      'isValidCategory': isValidCategory,
      'isValidWarehouse': isValidWarehouse,
      'isDuplicate': isDuplicate,
      'foundInStockOpname': foundInStockOpname,
      'canInsert': canInsert,
      'idWarehouse': idWarehouse,
      'jmlhSak': jmlhSak,
      'berat': berat,
      'idLokasi': idLokasi,
    };
  }

  // Helper methods untuk kemudahan penggunaan
  bool get hasStockData => jmlhSak != null && berat != null;

  bool get isValid => success && isValidFormat && isValidCategory && isValidWarehouse;

  String get stockInfo => hasStockData
      ? 'Sak: $jmlhSak, Berat: ${berat?.toStringAsFixed(1)} kg, Lokasi: $idLokasi'
      : 'Tidak ada data stock';

  @override
  String toString() {
    return 'LabelValidationResult{'
        'success: $success, '
        'message: $message, '
        'label: $label, '
        'labelType: $labelType, '
        'canInsert: $canInsert, '
        'isDuplicate: $isDuplicate, '
        'foundInStockOpname: $foundInStockOpname, '
        'isValidFormat: $isValidFormat, '
        'isValidCategory: $isValidCategory, '
        'isValidWarehouse: $isValidWarehouse, '
        'idWarehouse: $idWarehouse, '
        'jmlhSak: $jmlhSak, '
        'berat: $berat, '
        'idLokasi: $idLokasi'
        '}';
  }
}
