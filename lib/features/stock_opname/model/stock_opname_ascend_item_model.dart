class StockOpnameAscendItem {
  final String noSO;
  final int itemID;
  final String itemCode;
  final String? shelfCode;
  final String itemName;
  final double pcs;
  double? qtyFisik;
  double? qtyUsage;
  String usageRemark;
  bool isUpdateUsage;

  StockOpnameAscendItem({
    required this.noSO,
    required this.itemID,
    required this.itemCode,
    this.shelfCode,
    required this.itemName,
    required this.pcs,
    this.qtyFisik,
    this.qtyUsage,
    this.usageRemark = '',
    this.isUpdateUsage = false,
  });

  factory StockOpnameAscendItem.fromJson(Map<String, dynamic> json) {
    return StockOpnameAscendItem(
      noSO: json['NoSO'] ?? '',
      itemID: json['ItemID'] ?? 0,
      itemCode: json['ItemCode'] ?? '',
      shelfCode: json['ShelfCode'] ?? '-',
      itemName: json['ItemName'] ?? '',
      pcs: (json['Pcs'] as num?)?.toDouble() ?? 0.0,
      qtyFisik: (json['QtyFisik'] as num?)?.toDouble(),
      qtyUsage: (json['QtyUsage'] as num?)?.toDouble(),
      usageRemark: json['UsageRemark'] ?? '',
      isUpdateUsage: json['IsUpdateUsage'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'NoSO': noSO,
      'ItemID': itemID,
      'ItemCode': itemCode,
      'ShelfCode': shelfCode,
      'ItemName': itemName,
      'Pcs': pcs,
      'QtyFisik': qtyFisik,
      'QtyUsage': qtyUsage,
      'UsageRemark': usageRemark,
      'IsUpdateUsage': isUpdateUsage,
    };
  }
}
