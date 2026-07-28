class ReturV2PendingImportItem {
  final String invoiceNumber;
  final String? invoiceType;
  final String itemName;
  final String? stockCategoryName;
  final String? itemCode;
  final int quantity;
  final int? code;
  final String? sumberCode;
  final String? customerName;
  final int? idPembeli;

  const ReturV2PendingImportItem({
    required this.invoiceNumber,
    this.invoiceType,
    required this.itemName,
    this.stockCategoryName,
    this.itemCode,
    this.quantity = 0,
    this.code,
    this.sumberCode,
    this.customerName,
    this.idPembeli,
  });

  static String _s(dynamic v) => v?.toString() ?? '';
  static String? _sOpt(dynamic v) {
    if (v == null) return null;
    final text = v.toString();
    return text.isEmpty ? null : text;
  }

  static int _i(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  static int? _iOpt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  factory ReturV2PendingImportItem.fromJson(Map<String, dynamic> j) {
    return ReturV2PendingImportItem(
      invoiceNumber: _s(j['InvoiceNumber'] ?? j['invoiceNumber']),
      invoiceType: _sOpt(j['InvoiceType'] ?? j['invoiceType']),
      itemName: _s(j['ItemName'] ?? j['itemName']),
      stockCategoryName: _sOpt(
        j['StockCategoryName'] ?? j['stockCategoryName'],
      ),
      itemCode: _sOpt(j['ItemCode'] ?? j['itemCode']),
      quantity: _i(j['Quantity'] ?? j['quantity']),
      code: _iOpt(j['CODE'] ?? j['code']),
      sumberCode: _sOpt(j['SumberCode'] ?? j['sumberCode']),
      customerName: _sOpt(j['CustomerName'] ?? j['customerName']),
      idPembeli: _iOpt(j['IdPembeli'] ?? j['idPembeli']),
    );
  }
}

class ReturV2PendingImportGroup {
  final String invoiceNumber;
  final String? invoiceType;
  final List<ReturV2PendingImportItem> items;

  const ReturV2PendingImportGroup({
    required this.invoiceNumber,
    this.invoiceType,
    required this.items,
  });

  String? get customerName => items.isEmpty ? null : items.first.customerName;

  int get totalQuantity =>
      items.fold<int>(0, (sum, item) => sum + item.quantity);

  factory ReturV2PendingImportGroup.fromJson(Map<String, dynamic> j) {
    final itemsList = (j['items'] ?? []) as List;
    return ReturV2PendingImportGroup(
      invoiceNumber: (j['InvoiceNumber'] ?? j['invoiceNumber'])?.toString() ??
          '',
      invoiceType: (j['InvoiceType'] ?? j['invoiceType'])?.toString(),
      items: itemsList
          .map(
            (e) => ReturV2PendingImportItem.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
    );
  }
}
