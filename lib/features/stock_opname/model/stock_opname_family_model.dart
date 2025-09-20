class StockOpnameFamily {
  final String noSO;
  final int categoryID;
  final int familyID;
  final String familyName;
  final int totalItem;
  final int completeItem;

  StockOpnameFamily({
    required this.noSO,
    required this.categoryID,
    required this.familyID,
    required this.familyName,
    required this.totalItem,
    required this.completeItem,
  });

  factory StockOpnameFamily.fromJson(Map<String, dynamic> json) {
    return StockOpnameFamily(
      noSO: json['NoSO'] ?? '',
      categoryID: json['CategoryID'] ?? 0,
      familyID: json['FamilyID'] ?? 0,
      familyName: json['FamilyName'] ?? '',
      totalItem: json['TotalItem'] ?? 0,
      completeItem: json['CompleteItem'] ?? 0,
    );
  }
}
